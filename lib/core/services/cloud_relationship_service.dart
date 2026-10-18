import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/memory_model.dart';
import '../models/relationship_model.dart';
import '../models/calendar_event_model.dart';
import 'notification_service.dart';
import 'vibration_service.dart';
import '../cities.dart';
import '../constants.dart';
import 'image_compression_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

class CloudRelationshipService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _auth = AuthService();
  final SupabaseClient _supabase = Supabase.instance.client;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final NotificationService _notifications = NotificationService();

  // Collection References
  CollectionReference get _relationships => _firestore.collection('relationships');
  CollectionReference get _invites => _firestore.collection('invites');
  CollectionReference get _users => _firestore.collection('users');

  String? get currentUid => _auth.currentUid ?? _supabase.auth.currentUser?.id ?? FirebaseAuth.instance.currentUser?.uid;
  String? get _currentUid => currentUid;

  // Reactive Single-Source-of-Truth in-memory state for instant UI updates
  static final StreamController<RelationshipModel?> _relationshipStreamController =
      StreamController<RelationshipModel?>.broadcast();
  static RelationshipModel? _cachedRelationship;
  static RealtimeChannel? _relationshipChannel;
  static String? _subscribedRelUid;

  static final Map<String, StreamController<List<MemoryModel>>> _memoriesStreamControllers = {};
  static final Map<String, List<MemoryModel>> _cachedMemoriesMap = {};
  static final Map<String, RealtimeChannel> _memoriesChannels = {};

  static StreamController<List<MemoryModel>> _getMemoriesController(String relId) {
    return _memoriesStreamControllers.putIfAbsent(
      relId,
      () => StreamController<List<MemoryModel>>.broadcast(),
    );
  }

  static final Map<String, StreamController<List<CalendarEventModel>>> _eventsStreamControllers = {};
  static final Map<String, List<CalendarEventModel>> _cachedEventsMap = {};
  static final Set<String> _activeEventsListeners = {};

  static StreamController<List<CalendarEventModel>> _getEventsController(String relId) {
    return _eventsStreamControllers.putIfAbsent(
      relId,
      () => StreamController<List<CalendarEventModel>>.broadcast(),
    );
  }

  // Upload a memory with image
  Future<void> addMemory(String relId, File image, String caption, String location, {bool isStory = false, double? lat, double? lng, DateTime? unlockDate}) async {
    if (_currentUid == null) throw Exception('User not authenticated');
    
    // SECURITY: Enforce Memory limits
    final rel = await getRelationshipById(relId);
    if (rel == null) return;
    final isPlus = rel.isPlus;
    final maxMemories = isPlus ? AppSubscription.plusMaxMemories : AppSubscription.freeMaxMemories;
    
    int memoriesCount = 0;
    try {
      final res = await _supabase.from('memories').select('id').eq('relationship_id', relId);
      memoriesCount = (res as List).length;
    } catch (_) {
      try {
        final countRes = (await _relationships.doc(relId).collection('memories').count().get()).count;
        memoriesCount = countRes ?? 0;
      } catch (_) {}
    }
    if (memoriesCount >= maxMemories) {
      throw Exception('Memory limit reached. Upgrade to NextMeet+ for more space! ✨');
    }

    // Compress photo to lightweight WebP format (~60-90KB)
    final compressedImage = await ImageCompressionService.compressToWebp(image);
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}.webp';
    String imageUrl;
    
    try {
      final bytes = await compressedImage.readAsBytes();
      await _supabase.storage.from('memories').uploadBinary(
        '$relId/memories/$fileName',
        bytes,
        fileOptions: const FileOptions(contentType: 'image/webp', upsert: true),
      );
      imageUrl = _supabase.storage.from('memories').getPublicUrl('$relId/memories/$fileName');
    } catch (e) {
      debugPrint('Supabase storage memory upload fallback to Firebase: $e');
      try {
        if (FirebaseAuth.instance.currentUser == null) {
          await FirebaseAuth.instance.signInAnonymously();
        }
      } catch (_) {}
      final ref = _storage.ref().child('relationships/$relId/memories/$fileName');
      final uploadTask = await ref.putFile(
        compressedImage,
        SettableMetadata(contentType: 'image/webp'),
      );
      imageUrl = await uploadTask.ref.getDownloadURL();
    }

    final nowIso = DateTime.now().toIso8601String();
    final tempId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMemory = MemoryModel(
      id: tempId,
      imageUrl: imageUrl,
      caption: caption,
      location: location,
      date: DateTime.now(),
      isStory: isStory,
      lat: lat,
      lng: lng,
      unlockDate: unlockDate,
    );

    // 0ms INSTANT OPTIMISTIC EMISSION
    final currentList = _cachedMemoriesMap[relId] ?? [];
    final updatedList = [optimisticMemory, ...currentList.where((m) => m.id != tempId)];
    _cachedMemoriesMap[relId] = updatedList;
    _getMemoriesController(relId).add(List.from(updatedList));

    try {
      final insertRes = await _supabase.from('memories').insert({
        'relationship_id': relId,
        'uploader_id': _currentUid,
        'image_url': imageUrl,
        'caption': caption,
        'location': location,
        'is_story': isStory,
        'lat': lat,
        'lng': lng,
        'date': nowIso,
        'created_at': nowIso,
        'unlock_date': unlockDate?.toIso8601String(),
      }).select().maybeSingle();

      if (insertRes != null && insertRes['id'] != null) {
        final serverMemory = MemoryModel.fromFirestore(insertRes, id: insertRes['id']?.toString());
        final list = _cachedMemoriesMap[relId] ?? [];
        final idx = list.indexWhere((m) => m.id == tempId);
        if (idx != -1) {
          list[idx] = serverMemory;
        } else {
          list.insert(0, serverMemory);
        }
        _cachedMemoriesMap[relId] = list;
        _getMemoriesController(relId).add(List.from(list));
      }
    } catch (e) {
      debugPrint('Supabase insert memory warning: $e');
    }

    try {
      await _firestore.collection('relationships').doc(relId).collection('memories').add({
        'imageUrl': imageUrl,
        'caption': caption,
        'location': location,
        'date': FieldValue.serverTimestamp(),
        'addedBy': _currentUid,
        'isStory': isStory,
        'lat': lat,
        'lng': lng,
        'unlockDate': unlockDate != null ? Timestamp.fromDate(unlockDate) : null,
      });
    } catch (_) {}

    await logActivity(relId, 'memory', 'New memory saved: $location');
    await incrementStat(relId, 'memories');
  }

  Future<void> updateActivity(String relId) async {
    if (_currentUid == null) return;
    try {
      final relationship = await getRelationshipById(relId);
      if (relationship == null) return;
      final isUser1 = _currentUid == relationship.uid1;
      await _updateRelationshipData(relId, {
        isUser1 ? 'user1LastActive' : 'user2LastActive': DateTime.now(),
      });
    } catch (_) {}
  }

  Future<void> initNotifications(String relId) async {
    await _notifications.initialize();
    final token = await _notifications.getToken();
    if (token != null) await updateFcmToken(relId, token);
  }

  Future<void> updateFcmToken(String relId, String token) async {
    if (_currentUid == null) return;
    try {
      await _updateRelationshipData(relId, {'userTokens.$_currentUid': token});
    } catch (_) {}
  }

  Stream<List<MemoryModel>> streamMemories(String relId) async* {
    if (_cachedMemoriesMap.containsKey(relId)) {
      yield _cachedMemoriesMap[relId]!;
    }
    _setupMemoriesListener(relId);
    yield* _getMemoriesController(relId).stream;
  }

  void _setupMemoriesListener(String relId) {
    Future<void> fetchAndEmit() async {
      List<MemoryModel> supabaseMemories = [];
      try {
        final res = await _supabase
            .from('memories')
            .select()
            .eq('relationship_id', relId)
            .order('date', ascending: false);

        supabaseMemories = (res as List)
            .map((m) => MemoryModel.fromFirestore(m as Map<String, dynamic>, id: m['id']?.toString()))
            .toList();
      } catch (e) {
        debugPrint('Supabase streamMemories fetch warning: $e');
      }

      List<MemoryModel> firestoreMemories = [];
      try {
        final snap = await _firestore
            .collection('relationships')
            .doc(relId)
            .collection('memories')
            .orderBy('date', descending: true)
            .get();
        firestoreMemories = snap.docs
            .map((doc) => MemoryModel.fromFirestore(doc.data(), id: doc.id))
            .toList();
      } catch (e) {
        debugPrint('Firestore fallback streamMemories fetch warning: $e');
      }

      // Merge both remote sources so photos from either Supabase or Firestore are never lost
      final serverMemories = [...supabaseMemories, ...firestoreMemories];

      // Preserve any in-flight optimistic memories (id starts with 'local_') not yet returned by server
      final currentCached = _cachedMemoriesMap[relId] ?? [];
      final pendingOptimistic = currentCached.where((m) =>
          (m.id?.startsWith('local_') ?? false) &&
          !serverMemories.any((s) => (s.imageUrl.isNotEmpty && s.imageUrl == m.imageUrl) || s.id == m.id)
      ).toList();

      // Deduplicate memories by unique id and imageUrl
      final seenIds = <String>{};
      final seenUrls = <String>{};
      final mergedList = <MemoryModel>[];

      for (final m in [...pendingOptimistic, ...serverMemories]) {
        final id = m.id ?? '';
        final url = m.imageUrl;
        if ((id.isNotEmpty && seenIds.contains(id)) || (url.isNotEmpty && seenUrls.contains(url))) {
          continue;
        }
        if (id.isNotEmpty) seenIds.add(id);
        if (url.isNotEmpty) seenUrls.add(url);
        mergedList.add(m);
      }

      // Sort by date descending
      mergedList.sort((a, b) => b.date.compareTo(a.date));

      _cachedMemoriesMap[relId] = mergedList;
      _getMemoriesController(relId).add(mergedList);
    }

    fetchAndEmit();

    if (!_memoriesChannels.containsKey(relId)) {
      try {
        final channel = _supabase
            .channel('memories_stream_$relId')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'memories',
              callback: (payload) {
                fetchAndEmit();
              },
            )
            .subscribe();
        _memoriesChannels[relId] = channel;
      } catch (e) {
        debugPrint('Realtime channel memories subscription warning: $e');
      }

      // Also listen to Firestore collection as fallback sync
      try {
        _firestore
            .collection('relationships')
            .doc(relId)
            .collection('memories')
            .snapshots()
            .listen((_) => fetchAndEmit(), onError: (_) {});
      } catch (_) {}
    }
  }

  Future<void> deleteMemory(String relId, String memoryId, String imageUrl) async {
    if (_currentUid == null) return;

    // 0ms INSTANT OPTIMISTIC REMOVAL
    final currentList = _cachedMemoriesMap[relId] ?? [];
    final updatedList = currentList.where((m) => m.id != memoryId).toList();
    _cachedMemoriesMap[relId] = updatedList;
    _getMemoriesController(relId).add(List.from(updatedList));

    try {
      await _supabase.from('memories').delete().eq('id', memoryId);
      if (imageUrl.contains('supabase')) {
        final uri = Uri.tryParse(imageUrl);
        if (uri != null) {
          final segments = uri.pathSegments;
          final memoriesIdx = segments.indexOf('memories');
          if (memoriesIdx != -1 && memoriesIdx + 1 < segments.length) {
            final filePath = segments.sublist(memoriesIdx + 1).join('/');
            await _supabase.storage.from('memories').remove([filePath]);
          }
        }
      }
    } catch (e) {
      debugPrint('Supabase deleteMemory error: $e');
    }
    try {
      if (imageUrl.isNotEmpty) {
        final querySnap = await _firestore
            .collection('relationships')
            .doc(relId)
            .collection('memories')
            .where('imageUrl', isEqualTo: imageUrl)
            .get();
        for (var doc in querySnap.docs) {
          await doc.reference.delete();
        }
      }
      await _firestore.collection('relationships').doc(relId).collection('memories').doc(memoryId).delete();
      if (imageUrl.contains('firebasestorage')) {
        await _storage.refFromURL(imageUrl).delete();
      }
    } catch (_) {}
    await logActivity(relId, 'delete', 'A memory was removed');
  }

  Future<void> updateMemoryCaptions(String relId, String memoryId, {String? caption, String? p1Caption, String? p2Caption}) async {
    if (_currentUid == null) return;
    Map<String, dynamic> updates = {};
    if (caption != null) updates['caption'] = caption;
    if (p1Caption != null) updates['partner1Caption'] = p1Caption;
    if (p2Caption != null) updates['partner2Caption'] = p2Caption;
    if (updates.isNotEmpty) {
      final currentList = _cachedMemoriesMap[relId] ?? [];
      final idx = currentList.indexWhere((m) => m.id == memoryId);
      if (idx != -1) {
        final m = currentList[idx];
        currentList[idx] = m.copyWith(
          caption: caption ?? m.caption,
          partner1Caption: p1Caption ?? m.partner1Caption,
          partner2Caption: p2Caption ?? m.partner2Caption,
        );
        _cachedMemoriesMap[relId] = currentList;
        _getMemoriesController(relId).add(List.from(currentList));
      }
      try {
        await _supabase.from('memories').update(updates).eq('id', memoryId);
      } catch (e) {
        debugPrint('Supabase updateMemoryCaptions error: $e');
      }
      try {
        await _firestore.collection('relationships').doc(relId).collection('memories').doc(memoryId).update(updates);
      } catch (_) {}
    }
  }

  Future<String> createJourney(RelationshipModel localData) async {
    final uid = _currentUid ?? _auth.currentUid ?? _supabase.auth.currentUser?.id;
    if (uid == null) throw Exception('User not authenticated');
    final String code = (math.Random().nextInt(900000) + 100000).toString();
    final relDocRef = _relationships.doc();
    final relationship = localData.copyWith(
      id: relDocRef.id, 
      uid1: uid, 
      uids: [uid], 
      inviteCode: code, 
      createdAt: DateTime.now(), 
      status: 'waiting',
    );

    // 1. Supabase Sync (Primary real-time database)
    try {
      await _supabase.from('relationships').upsert({
        'id': relDocRef.id,
        'uid1': uid,
        'uids': [uid],
        'invite_code': code,
        'status': 'waiting',
        'data': relationship.toFirestoreMap(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Supabase createJourney sync warning: $e');
    }

    // 2. Firestore Sync & Invites
    try {
      await relDocRef.set(relationship.toFirestore());
      final userEmail = _auth.currentUser?.email ?? 'Unknown Email';
      await _invites.doc(code).set({
        'creatorUid': uid, 
        'relationshipId': relDocRef.id, 
        'status': 'pending', 
        'createdAt': FieldValue.serverTimestamp(),
        'creatorEmail': userEmail
      });
    } catch (e) {
      debugPrint('Firestore createJourney sync warning: $e');
    }

    // 3. Admin Dashboard Sync
    try {
      await _firestore.collection('pending_relationships').doc(relDocRef.id).set({
        'relId': relDocRef.id,
        'uid1': uid,
        'userName1': localData.userName1 ?? "Partner 1",
        'inviteCode': code,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _firestore.collection('system_stats').doc('global').set({
        'total_created_journeys': FieldValue.increment(1),
        'confirmed_waiting_users': FieldValue.increment(1),
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error syncing createJourney to admin dashboard: $e');
    }

    // Update local cache so UI reacts immediately
    _cachedRelationship = relationship;
    _relationshipStreamController.add(relationship);
    
    return code;
  }

  Future<RelationshipModel?> joinJourney(String code, String partnerCity, String myName, String partnerPetName, {double? lat, double? lng}) async {
    if (_currentUid == null) throw Exception('User not authenticated');

    // Check if user is already in a relationship
    final existingRel = await streamRelationship().first;
    if (existingRel != null && existingRel.status == 'active') {
      throw Exception('You are already in an active relationship! ❤️');
    }

    final joinedRelationship = await _firestore.runTransaction((transaction) async {
      final inviteDoc = await transaction.get(_invites.doc(code));
      if (!inviteDoc.exists) {
        throw Exception('Invalid invite code. Please check and try again! ❤️');
      }
      
      if (inviteDoc.get('status') == 'accepted') {
        throw Exception('This invite code has already been used! ❤️');
      }

      final creatorUid = inviteDoc.get('creatorUid');
      if (creatorUid == _currentUid) {
        throw Exception('You cannot join your own journey! Send the code to your partner instead. ❤️');
      }

      final relId = inviteDoc.get('relationshipId');
      final relDocRef = _relationships.doc(relId);
      final relDoc = await transaction.get(relDocRef);
      if (!relDoc.exists) {
        throw Exception('Relationship data not found. It might have been deleted. ❤️');
      }

      double distance = 0.0;
      final creatorLat = (relDoc.data() as Map<String, dynamic>)['user1Lat'] as double?;
      final creatorLng = (relDoc.data() as Map<String, dynamic>)['user1Lng'] as double?;
      if (creatorLat != null && creatorLng != null && lat != null && lng != null) {
        distance = double.parse(CityData.calculateDistance(creatorLat, creatorLng, lat, lng).toStringAsFixed(1));
      }

      transaction.update(relDocRef, {
        'uid2': _currentUid, 
        'uids': [creatorUid, _currentUid], 
        'userName2': myName, 
        'user2PartnerNickname': partnerPetName, 
        'userLocation2': partnerCity, 
        'user2Lat': lat, 
        'user2Lng': lng, 
        'distanceKm': distance, 
        'status': 'active'
      });
      transaction.update(_invites.doc(code), {'status': 'accepted'});
      
      final data = relDoc.data() as Map<String, dynamic>;
      return RelationshipModel.fromFirestore({
        ...data, 
        'uid2': _currentUid, 
        'uids': [creatorUid, _currentUid], 
        'userName2': myName, 
        'user2PartnerNickname': partnerPetName, 
        'userLocation2': partnerCity, 
        'user2Lat': lat, 
        'user2Lng': lng, 
        'distanceKm': distance, 
        'status': 'active'
      }, id: relId);
    });

    if (joinedRelationship != null && joinedRelationship.id != null) {
      final relId = joinedRelationship.id!;
      final creatorUid = joinedRelationship.uid1;

      // Clean up any abandoned test journeys previously created by this user
      try {
        final orphanedWaiting = await _relationships
            .where('uid1', isEqualTo: _currentUid)
            .where('status', isEqualTo: 'waiting')
            .get();
        for (final doc in orphanedWaiting.docs) {
          if (doc.id != relId) {
            await doc.reference.delete();
          }
        }
      } catch (e) {
        debugPrint('Non-critical cleanup warning for orphaned waiting journeys: $e');
      }

      // Non-blocking metrics & admin tracking
      try {
        await _firestore.collection('accepted_relationships').doc(relId).set({
          'relId': relId,
          'uid1': creatorUid,
          'uid2': _currentUid,
          'userName1': joinedRelationship.userName1 ?? "Partner 1",
          'userName2': myName,
          'acceptedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await _firestore.collection('pending_relationships').doc(relId).delete();

        await _firestore.collection('system_stats').doc('global').set({
          'confirmed_active_couples': FieldValue.increment(1),
          'confirmed_waiting_users': FieldValue.increment(-1),
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Non-critical admin sync warning in joinJourney: $e');
      }

      // Supabase sync
      try {
        await _supabase.from('relationships').upsert({
          'id': relId,
          'uid1': creatorUid,
          'uid2': _currentUid,
          'uids': [creatorUid, _currentUid],
          'status': 'active',
          'invite_code': code,
          'data': joinedRelationship.toFirestoreMap(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('Supabase joinJourney sync warning: $e');
      }
    }

    return joinedRelationship;
  }

  Future<RelationshipModel?> getRelationshipById(String relId) async {
    try {
      final res = await _supabase.from('relationships').select().eq('id', relId).maybeSingle();
      if (res != null) {
        final dataMap = res['data'] is Map ? Map<String, dynamic>.from(res['data'] as Map) : <String, dynamic>{};
        dataMap['id'] = res['id'];
        dataMap['uid1'] = res['uid1'];
        dataMap['uid2'] = res['uid2'];
        dataMap['status'] = res['status'];
        dataMap['inviteCode'] = res['invite_code'];
        return RelationshipModel.fromFirestoreMap(dataMap, id: res['id']?.toString());
      }
    } catch (_) {}

    try {
      final doc = await _relationships.doc(relId).get();
      if (doc.exists) {
        return RelationshipModel.fromFirestore(doc.data() as Map<String, dynamic>, id: doc.id);
      }
    } catch (_) {}
    return null;
  }

  Stream<RelationshipModel?> streamRelationship() async* {
    final uid = _currentUid;
    if (uid == null) {
      yield null;
      return;
    }

    if (_cachedRelationship != null) {
      yield _cachedRelationship;
    }

    _setupRelationshipListener(uid);
    yield* _relationshipStreamController.stream;
  }

  void _setupRelationshipListener(String uid) {
    Future<void> fetchAndEmit() async {
      try {
        final res = await _supabase
            .from('relationships')
            .select()
            .or('uid1.eq.$uid,uid2.eq.$uid,uids.cs.{$uid}');

        if (res.isEmpty) {
          _cachedRelationship = null;
          _relationshipStreamController.add(null);
          return;
        }

        final activeRel = res.firstWhere(
          (r) => r['status'] == 'active',
          orElse: () => res.first,
        );

        final dataMap = activeRel['data'] is Map
            ? Map<String, dynamic>.from(activeRel['data'] as Map)
            : <String, dynamic>{};
        dataMap['id'] = activeRel['id'];
        dataMap['uid1'] = activeRel['uid1'];
        dataMap['uid2'] = activeRel['uid2'];
        dataMap['status'] = activeRel['status'];
        dataMap['inviteCode'] = activeRel['invite_code'];

        final model = RelationshipModel.fromFirestoreMap(dataMap, id: activeRel['id']?.toString());
        _cachedRelationship = model;
        _relationshipStreamController.add(model);
      } catch (e) {
        debugPrint('Supabase streamRelationship fetch warning: $e');
        try {
          final snap = await _relationships.where('uids', arrayContains: uid).get();
          if (snap.docs.isNotEmpty) {
            final activeDoc = snap.docs.cast<QueryDocumentSnapshot?>().firstWhere(
              (doc) => (doc?.data() as Map<String, dynamic>?)?['status'] == 'active',
              orElse: () => null,
            );
            final target = activeDoc ?? snap.docs.first;
            final model = RelationshipModel.fromFirestore(target.data() as Map<String, dynamic>, id: target.id);
            _cachedRelationship = model;
            _relationshipStreamController.add(model);
            return;
          }
        } catch (_) {}
        if (_cachedRelationship == null) {
          _relationshipStreamController.add(null);
        }
      }
    }

    fetchAndEmit();

    if (_subscribedRelUid != uid) {
      _subscribedRelUid = uid;
      _relationshipChannel?.unsubscribe();
      try {
        _relationshipChannel = _supabase
            .channel('rel_stream_$uid')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'relationships',
              callback: (payload) {
                fetchAndEmit();
              },
            )
            .subscribe();
      } catch (e) {
        debugPrint('Realtime channel subscription warning: $e');
      }
    }
  }


  Future<void> _updateRelationshipData(String relId, Map<String, dynamic> updates) async {
    // 0. INSTANT OPTIMISTIC LOCAL EMISSION (0ms UI Update)
    if (_cachedRelationship == null || _cachedRelationship!.id != relId) {
      try {
        _cachedRelationship = await getRelationshipById(relId);
      } catch (_) {}
    }

    if (_cachedRelationship != null && _cachedRelationship!.id == relId) {
      final currentMap = _cachedRelationship!.toFirestoreMap();
      updates.forEach((k, v) {
        if (v is DateTime) {
          currentMap[k] = v;
        } else if (v is Timestamp) {
          currentMap[k] = v.toDate();
        } else {
          currentMap[k] = v;
        }
      });
      _cachedRelationship = RelationshipModel.fromFirestoreMap(currentMap, id: relId);
      _relationshipStreamController.add(_cachedRelationship);
    }

    // 1. Update Supabase
    try {
      final res = await _supabase.from('relationships').select('data').eq('id', relId).maybeSingle();
      if (res != null) {
        final currentData = res['data'] is Map ? Map<String, dynamic>.from(res['data'] as Map) : <String, dynamic>{};
        updates.forEach((k, v) {
          if (v is DateTime) {
            currentData[k] = v.toIso8601String();
          } else if (v is Timestamp) {
            currentData[k] = v.toDate().toIso8601String();
          } else if (v is FieldValue) {
            currentData[k] = DateTime.now().toIso8601String();
          } else {
            currentData[k] = v;
          }
        });

        final rowUpdates = <String, dynamic>{
          'data': currentData,
          'updated_at': DateTime.now().toIso8601String(),
        };

        if (updates.containsKey('status')) rowUpdates['status'] = updates['status'];
        if (updates.containsKey('distanceKm')) rowUpdates['distance_km'] = updates['distanceKm'];
        if (updates.containsKey('streakCount')) rowUpdates['streak_count'] = updates['streakCount'];
        if (updates.containsKey('isPlus')) rowUpdates['is_plus'] = updates['isPlus'];

        await _supabase.from('relationships').update(rowUpdates).eq('id', relId);
      }
    } catch (e) {
      debugPrint('Supabase _updateRelationshipData warning: $e');
    }

    // 2. Best-effort Firestore update
    try {
      await _relationships.doc(relId).update(updates);
    } catch (e) {
      debugPrint('Firestore update warning: $e');
    }
  }

  Future<void> sendTouch(String relId, String type, {String? emoji}) async {
    if (_currentUid == null) return;
    final touchData = <String, dynamic>{
      'lastTouchType': type,
      'lastTouchFrom': _currentUid,
      'lastTouchTime': DateTime.now(),
    };
    if (emoji != null) touchData['lastTouchEmoji'] = emoji;
    await _updateRelationshipData(relId, touchData);
    String logTitle = 'Sent a "Touch" ❤️';
    if (type == 'miss') {
      logTitle = 'Sent a "Miss You" 🥺';
    } else if (type == 'hug') {
      logTitle = 'Sent a "Digital Hug" 🤗';
    } else if (type == 'emoji') {
      logTitle = emoji != null ? 'Sent a Reaction $emoji' : 'Sent a Reaction ✨';
    }
    await logActivity(relId, 'nudge', logTitle);
  }

  Future<void> updateMyStatus(String relId, RelationshipModel data, {String? mood, String? city, double? lat, double? lng}) async {
    if (_currentUid == null) return;
    final isMe1 = _currentUid == data.uid1;
    final updates = <String, dynamic>{};
    final tzOffset = DateTime.now().timeZoneOffset.inMinutes;
    if (isMe1) {
      updates['user1TimezoneOffset'] = tzOffset;
    } else {
      updates['user2TimezoneOffset'] = tzOffset;
    }
    if (mood != null) {
      if (isMe1) {
        updates['userMood1'] = mood;
      } else {
        updates['userMood2'] = mood;
      }
      await logActivity(relId, 'mood', 'Mood Updated: $mood ✨');
    }
    if (lat != null && lng != null) {
      if (isMe1) { updates['user1Lat'] = lat; updates['user1Lng'] = lng; }
      else { updates['user2Lat'] = lat; updates['user2Lng'] = lng; }
    }
    if (city != null) {
      final cityTrimmed = city.trim();
      if (isMe1) {
        updates['userLocation1'] = cityTrimmed;
      } else {
        updates['userLocation2'] = cityTrimmed;
      }
      await logActivity(relId, 'location', 'Location Updated: $cityTrimmed 📍');
    }
    final l1Lat = isMe1 ? lat : data.user1Lat; 
    final l1Lng = isMe1 ? lng : data.user1Lng;
    final l2Lat = isMe1 ? data.user2Lat : lat; 
    final l2Lng = isMe1 ? data.user2Lng : lng;

    if (l1Lat != null && l1Lng != null && l2Lat != null && l2Lng != null) {
      final distance = CityData.calculateDistance(l1Lat, l1Lng, l2Lat, l2Lng);
      double finalDist = double.parse(distance.toStringAsFixed(1));
      if (distance > 0 && finalDist == 0) finalDist = 0.1;
      updates['distanceKm'] = finalDist;
    }
    if (updates.isNotEmpty) await _updateRelationshipData(relId, updates);
  }

  Future<void> updateRelationshipDetails(String relId, Map<String, dynamic> updates) async {
    if (updates.isNotEmpty) {
      await _updateRelationshipData(relId, updates);
      await logActivity(relId, 'update', 'Journey details updated ✨');
    }
  }

  Future<void> updateActivityAndStreak(String relId, RelationshipModel rel) async {
    if (_currentUid == null) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final myLastActive = _currentUid == rel.uid1 ? rel.user1LastActive : rel.user2LastActive;
    if (myLastActive != null && now.difference(myLastActive).inHours < 4 && rel.streakCount > 0) {
      if (rel.lastStreakIncrement != null) {
        final lastIncDay = DateTime(rel.lastStreakIncrement!.year, rel.lastStreakIncrement!.month, rel.lastStreakIncrement!.day);
        if (lastIncDay == today) return; 
      }
    }
    Map<String, dynamic> updates = {};
    if (_currentUid == rel.uid1) {
      updates['user1LastActive'] = Timestamp.fromDate(now);
    } else {
      updates['user2LastActive'] = Timestamp.fromDate(now);
    }
    bool isReset = false;
    if (rel.lastStreakIncrement != null && now.difference(rel.lastStreakIncrement!).inHours > 48) {
      updates['streakCount'] = 0; isReset = true;
    }
    bool alreadyIncrementedToday = rel.lastStreakIncrement != null && DateTime(rel.lastStreakIncrement!.year, rel.lastStreakIncrement!.month, rel.lastStreakIncrement!.day) == today;
    if (!alreadyIncrementedToday) {
      final u1Recent = rel.user1LastActive != null && now.difference(rel.user1LastActive!).inHours <= 36;
      final u2Recent = rel.user2LastActive != null && now.difference(rel.user2LastActive!).inHours <= 36;
      if ((_currentUid == rel.uid1 || u1Recent) && (_currentUid == rel.uid2 || u2Recent)) {
        final newCount = (isReset ? 0 : rel.streakCount) + 1;
        updates['streakCount'] = newCount;
        updates['stats.streak'] = newCount; // Sync for achievements
        updates['lastStreakIncrement'] = Timestamp.fromDate(now);
      }
    }
    if (updates.isNotEmpty) {
      if (!alreadyIncrementedToday) {
        final quotes = [
          "Every day apart is one day closer to our forever ❤️", 
          "Distance means so little when someone means so much ✨", 
          "True love knows no distance 💓", 
          "Together or apart, you are always in my heart 🥺"
        ];
        updates['loveQuote'] = quotes[math.Random().nextInt(quotes.length)];
      }
      await _updateRelationshipData(relId, updates);
    }
  }

  Future<void> logActivity(String relId, String type, String title, {String? detail}) async {
    if (_currentUid == null) return;
    try {
      await _relationships.doc(relId).collection('activities').add({'type': type, 'title': title, 'detail': detail, 'timestamp': FieldValue.serverTimestamp(), 'fromUid': _currentUid});
    } catch (_) {}
  }

  Stream<QuerySnapshot> streamActivities(String relId) {
    return _relationships.doc(relId).collection('activities').orderBy('timestamp', descending: true).snapshots();
  }

  // --- TRIP PLANNER ---
  Future<void> updateTripDetails(String relId, {String? dest, DateTime? date, DateTime? endDate, double? budget, String? notes, String? accommodation, String? transport, String? mustSee, String? mood, String? story}) async {
    final relDoc = await _relationships.doc(relId).get();
    if (!relDoc.exists) return;
    
    final bool isPlus = relDoc.get('isPlus') ?? false;
    final int maxTrips = isPlus ? AppSubscription.plusMaxActiveTrips : AppSubscription.freeMaxActiveTrips;
    
    // Check if we are "Starting" a new trip (destination was null/empty and now provided)
    final existingDest = relDoc.get('tripDestination') as String?;
    if ((existingDest == null || existingDest.isEmpty) && (dest != null && dest.isNotEmpty)) {
      // For now, NextMeet uses a flat structure for the current trip. 
      // If we are "Starting" a trip, we just ensure it's not blocked by future 10-trip draft logic if we implement it.
      // But for this phase, the limit is simply a count of active trips in the subcollection if used.
      // Since the user only has ONE flat trip field for now, the '1' limit is naturally enforced.
      // I'll add a placeholder check for the '10' limit to be 'Future-Proof'.
      final tripsCount = 1; // Since it's a flat document for now.
      if (tripsCount > maxTrips) {
        throw Exception('You have reached your active trip limit. Upgrade to NextMeet+! ✈️');
      }
    }

    final updates = <String, dynamic>{};
    if (dest != null) updates['tripDestination'] = dest;
    if (date != null) updates['tripDate'] = Timestamp.fromDate(date);
    if (endDate != null) updates['tripEndDate'] = Timestamp.fromDate(endDate);
    if (budget != null) updates['tripBudget'] = budget;
    if (notes != null) updates['tripNotes'] = notes;
    if (accommodation != null) updates['tripAccommodation'] = accommodation;
    if (transport != null) updates['tripTransport'] = transport;
    if (mustSee != null) updates['tripMustSee'] = mustSee;
    if (mood != null) updates['tripMood'] = mood;
    if (story != null) updates['tripStory'] = story;
    if (updates.isNotEmpty) {
      await _updateRelationshipData(relId, updates);
      await logActivity(relId, 'update', 'Trip Details Updated ✈️');
    }
  }

  Future<void> updateTripExcitement(String relId, String uid, bool excited) async {
    await _updateRelationshipData(relId, {'tripExcitement.$uid': excited});
  }

  Future<void> addItineraryItem(String relId, String title, String description, DateTime date, {String category = 'Sightseeing', String? notes, String slot = 'Morning'}) async {
    await _relationships.doc(relId).collection('itinerary').add({'title': title, 'description': description, 'date': Timestamp.fromDate(date), 'category': category, 'notes': notes, 'slot': slot, 'plannedBy': _currentUid, 'createdAt': FieldValue.serverTimestamp()});
  }

  Future<void> updateItineraryItem(String relId, String itemId, {String? title, String? description, String? notes, String? category, String? slot}) async {
    Map<String, dynamic> data = {};
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (notes != null) data['notes'] = notes;
    if (category != null) data['category'] = category;
    if (slot != null) data['slot'] = slot;
    await _relationships.doc(relId).collection('itinerary').doc(itemId).update(data);
  }

  Future<void> addTask(String relId, String title, {String? assignedTo}) async {
    await _relationships.doc(relId).collection('tasks').add({
      'title': title, 
      'isCompleted': false, 
      'assignedTo': assignedTo,
      'createdAt': FieldValue.serverTimestamp()
    });
    await logActivity(relId, 'update', 'New Task Added: $title ✅');
  }

  Future<void> toggleTask(String relId, String taskId, bool completed) async {
    await _relationships.doc(relId).collection('tasks').doc(taskId).update({'isCompleted': completed});
    if (completed) await logActivity(relId, 'update', 'Task Completed! 🎉');
  }

  Stream<QuerySnapshot> streamTasks(String relId) => _relationships.doc(relId).collection('tasks').orderBy('createdAt', descending: false).snapshots();
  Future<void> deleteTask(String relId, String taskId) async => _relationships.doc(relId).collection('tasks').doc(taskId).delete();

  Future<void> addPackingItem(String relId, String title, {String? assignedTo}) async {
    await _relationships.doc(relId).collection('packing_list').add({
      'title': title, 
      'isCompleted': false, 
      'assignedTo': assignedTo,
      'createdAt': FieldValue.serverTimestamp()
    });
  }

  Future<void> togglePackingItem(String relId, String itemId, bool completed) async {
    await _relationships.doc(relId).collection('packing_list').doc(itemId).update({'isCompleted': completed});
  }

  Stream<QuerySnapshot> streamPackingItems(String relId) => _relationships.doc(relId).collection('packing_list').orderBy('createdAt', descending: false).snapshots();
  Future<void> deletePackingItem(String relId, String itemId) async => _relationships.doc(relId).collection('packing_list').doc(itemId).delete();

  Future<void> addTripExpense(String relId, String title, double amount, String category, {String? paidBy}) async {
    await _relationships.doc(relId).collection('expenses').add({'title': title, 'amount': amount, 'category': category, 'paidBy': paidBy ?? _currentUid, 'createdAt': FieldValue.serverTimestamp()});
  }

  Future<void> updateTripExpense(String relId, String expenseId, String title, double amount, String category) async {
    await _relationships.doc(relId).collection('expenses').doc(expenseId).update({
      'title': title,
      'amount': amount,
      'category': category,
    });
  }

  Future<void> deleteTripExpense(String relId, String expenseId) async => _relationships.doc(relId).collection('expenses').doc(expenseId).delete();
  Stream<QuerySnapshot> streamExpenses(String relId) => _relationships.doc(relId).collection('expenses').orderBy('createdAt', descending: true).snapshots();
  Stream<QuerySnapshot> streamItinerary(String relId) => _relationships.doc(relId).collection('itinerary').orderBy('date', descending: false).snapshots();
  Future<void> deleteItineraryItem(String relId, String itemId) async => _relationships.doc(relId).collection('itinerary').doc(itemId).delete();

  Future<void> resetTripData(String relId) async {
    await _updateRelationshipData(relId, {
      'tripDestination': null,
      'tripDate': null,
      'tripBudget': null,
      'tripNotes': null,
      'tripAccommodation': null,
      'tripTransport': null,
      'tripMustSee': null,
      'tripMood': null,
      'tripStory': null,
      'tripExcitement': null
    });
    for (final coll in ['tasks', 'packing_list', 'expenses', 'itinerary']) {
      try {
        final docs = await _relationships.doc(relId).collection(coll).get();
        for (final doc in docs.docs) {
          await doc.reference.delete();
        }
      } catch (_) {}
    }
    await logActivity(relId, 'update', 'Trip Reset/Deleted 🗑️');
  }

  // --- PROFILE ---
  Future<void> updateProfile(String relId, {String? name1, String? loc1, String? photo1, String? nick1, double? lat1, double? lng1, String? name2, String? loc2, String? photo2, String? nick2, double? lat2, double? lng2}) async {
    final updates = <String, dynamic>{};
    if (name1 != null) updates['userName1'] = name1; if (loc1 != null) updates['userLocation1'] = loc1; if (photo1 != null) updates['userPhoto1'] = photo1; if (nick1 != null) updates['user1PartnerNickname'] = nick1; if (lat1 != null) updates['user1Lat'] = lat1; if (lng1 != null) updates['user1Lng'] = lng1;
    if (name2 != null) updates['userName2'] = name2; if (loc2 != null) updates['userLocation2'] = loc2; if (photo2 != null) updates['userPhoto2'] = photo2; if (nick2 != null) updates['user2PartnerNickname'] = nick2; if (lat2 != null) updates['user2Lat'] = lat2; if (lng2 != null) updates['user2Lng'] = lng2;
    if (updates.isNotEmpty) await _updateRelationshipData(relId, updates);
  }

  Future<String> uploadProfilePhoto(String relId, Uint8List imageBytes) async {
    if (imageBytes.isEmpty) {
      throw Exception('Image bytes are empty! Scoped storage issue.');
    }

    // Compress profile avatar to lightweight WebP format (~30-50KB)
    final compressedBytes = await ImageCompressionService.compressBytesToWebp(imageBytes);
    final String fileName = 'profile_${_currentUid}_${DateTime.now().millisecondsSinceEpoch}.webp';
    
    try {
      await _supabase.storage.from('memories').uploadBinary(
        '$relId/profiles/$fileName',
        compressedBytes,
        fileOptions: const FileOptions(contentType: 'image/webp', upsert: true),
      );
      return _supabase.storage.from('memories').getPublicUrl('$relId/profiles/$fileName');
    } catch (e) {
      debugPrint('Supabase uploadProfilePhoto fallback to Firebase: $e');
      try {
        if (FirebaseAuth.instance.currentUser == null) {
          await FirebaseAuth.instance.signInAnonymously();
        }
      } catch (_) {}
      final ref = _storage.ref().child('relationships/$relId/profiles/$fileName');
      final metadata = SettableMetadata(contentType: 'image/webp');
      final uploadTask = await ref.putData(compressedBytes, metadata);
      return await uploadTask.ref.getDownloadURL();
    }
  }

  // --- PRIVATE SPACE ---
  Future<void> updatePrivateSpacePin(String relId, String? pin) async => await _updateRelationshipData(relId, {
    'privateSpacePin': pin,
    'pinResetRequestBy': null,
    'pinResetRequestAt': null,
    'pinResetApproved': false,
  });
  Future<void> updatePrivateSpaceTimeout(String relId, String timeout) async => await _updateRelationshipData(relId, {'privateSpaceTimeout': timeout});
  Future<void> requestPinReset(String relId) async => await _updateRelationshipData(relId, {'pinResetRequestBy': _currentUid, 'pinResetRequestAt': DateTime.now(), 'pinResetApproved': false});
  Future<void> approvePinReset(String relId) async => await _updateRelationshipData(relId, {'pinResetApproved': true});
  Future<void> finalizePinReset(String relId, String newPin) async => await _updateRelationshipData(relId, {'privateSpacePin': newPin, 'pinResetRequestBy': null, 'pinResetRequestAt': null, 'pinResetApproved': false});
  Future<void> cancelPinReset(String relId) async => await _updateRelationshipData(relId, {'pinResetRequestBy': null, 'pinResetRequestAt': null, 'pinResetApproved': false});
  Future<void> generatePinResetOtps(String relId) async {
    final otp1 = (100000 + math.Random().nextInt(900000)).toString();
    final otp2 = (100000 + math.Random().nextInt(900000)).toString();
    await _updateRelationshipData(relId, {'pinResetOtp1': otp1, 'pinResetOtp2': otp2, 'pinResetOtpExpiry': DateTime.now().add(const Duration(minutes: 15))});
  }
  Future<bool> verifyPinResetOtps(String relId, String otp1, String otp2) async {
    final rel = await getRelationshipById(relId);
    if (rel != null && rel.pinResetOtp1 == otp1 && rel.pinResetOtp2 == otp2) {
      await approvePinReset(relId);
      return true;
    }
    return false;
  }

  // --- PRIVATE SPACE / ELITE TOOLS ---
  Future<void> updateSanctuaryPresence(String relId, bool isIn) async {
    if (_currentUid == null) return;
    final rel = await getRelationshipById(relId);
    if (rel == null) return;
    final isUser1 = _currentUid == rel.uid1;
    await _updateRelationshipData(relId, {
      isUser1 ? 'u1InSanctuary' : 'u2InSanctuary': isIn,
      isUser1 ? 'u1SanctuaryLastSeen' : 'u2SanctuaryLastSeen': DateTime.now(),
    });
  }
  
  Future<void> updateSanctuaryStatus(bool isIn) async {
    if (_currentUid == null) return;
    final rel = await streamRelationship().first;
    if (rel?.id != null) {
      await updateSanctuaryPresence(rel!.id!, isIn);
    }
  }

  Future<void> updateSketchpadData(String relId, String? data) async {
    if (_currentUid == null) return;
    await _updateRelationshipData(relId, {
      'sketchpadData': data,
      'sketchpadLastUpdate': DateTime.now(),
      'sketchpadUpdatedBy': _currentUid,
    });
  }

  Future<void> clearSketchpadData(String relId) async {
    await updateSketchpadData(relId, null);
  }

  Future<void> addVoiceWhisper(String relId, File audioFile) async {
    if (_currentUid == null) return;
    final String fileName = 'whisper_${DateTime.now().millisecondsSinceEpoch}.m4a';
    final ref = _storage.ref().child('relationships/$relId/whispers/$fileName');
    final uploadTask = await ref.putFile(audioFile);
    final String url = await uploadTask.ref.getDownloadURL();

    await _relationships.doc(relId).collection('whispers').add({
      'audioUrl': url,
      'sentBy': _currentUid,
      'timestamp': FieldValue.serverTimestamp(),
    });
    await logActivity(relId, 'voice_note', 'Sent a new Private Voice Note 📼');
  }

  Stream<QuerySnapshot> streamVoiceWhispers(String relId) {
    return _relationships.doc(relId).collection('whispers').orderBy('timestamp', descending: true).snapshots();
  }

  Future<void> deleteVoiceWhisper(String relId, String whisperId, String url) async {
    if (_currentUid == null) return;
    await _relationships.doc(relId).collection('whispers').doc(whisperId).delete();
    try { await _storage.refFromURL(url).delete(); } catch (_) {}
  }

  Future<void> clearPrivateSpaceData(String relId) async {
    final colls = ['private_photos', 'private_notes', 'love_letters'];
    for (final c in colls) {
      final docs = await _relationships.doc(relId).collection(c).get();
      for (final d in docs.docs) {
        await d.reference.delete();
      }
    }
    
    // Reset storage counter
    await _relationships.doc(relId).update({'privateSpaceStorageBytes': 0});
  }

  Stream<QuerySnapshot> streamPrivatePhotos(String relId) => _relationships.doc(relId).collection('private_photos').orderBy('timestamp', descending: true).snapshots();
  Future<void> addPrivatePhoto(String relId, String url, int size) async {
    try {
      await _supabase.from('private_photos').insert({
        'relationship_id': relId,
        'url': url,
        'size_bytes': size,
        'uploaded_by': _currentUid,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Supabase addPrivatePhoto notice: $e');
    }
    try {
      await _relationships.doc(relId).collection('private_photos').add({
        'url': url,
        'sizeBytes': size,
        'uploadedBy': _currentUid,
        'timestamp': FieldValue.serverTimestamp(),
      });
      await _relationships.doc(relId).set({
        'privateSpaceStorageBytes': FieldValue.increment(size),
      }, SetOptions(merge: true));
    } catch (_) {}
  }
  Future<void> deletePrivatePhoto(String relId, String photoId, String url, int size) async {
    try {
      await _supabase.from('private_photos').delete().eq('id', photoId);
    } catch (_) {}
    try {
      await _relationships.doc(relId).collection('private_photos').doc(photoId).delete();
    } catch (_) {}
    try {
      if (url.contains('supabase.co')) {
        final uri = Uri.parse(url);
        final segments = uri.pathSegments;
        final memoriesIdx = segments.indexOf('memories');
        if (memoriesIdx != -1 && memoriesIdx + 1 < segments.length) {
          final filePath = segments.sublist(memoriesIdx + 1).join('/');
          await _supabase.storage.from('memories').remove([filePath]);
        }
      } else {
        await _storage.refFromURL(url).delete();
      }
    } catch (_) {}
    try {
      await _relationships.doc(relId).set({
        'privateSpaceStorageBytes': FieldValue.increment(-size),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Stream<QuerySnapshot> streamPrivateNotes(String relId) => _relationships.doc(relId).collection('private_notes').orderBy('timestamp', descending: true).snapshots();
  Future<void> addPrivateNote(String relId, String title, String content, String category) async {
    try {
      await _supabase.from('private_notes').insert({
        'relationship_id': relId,
        'author_id': _currentUid ?? 'partner',
        'title': title,
        'content': content,
        'category': category,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Supabase addPrivateNote notice: $e');
    }
    await _relationships.doc(relId).collection('private_notes').add({'title': title, 'content': content, 'category': category, 'createdBy': _currentUid, 'timestamp': FieldValue.serverTimestamp()});
  }
  Future<void> deletePrivateNote(String relId, String noteId) async {
    try {
      await _supabase.from('private_notes').delete().eq('id', noteId);
    } catch (_) {}
    await _relationships.doc(relId).collection('private_notes').doc(noteId).delete();
  }

  Stream<QuerySnapshot> streamLoveLetters(String relId) => _relationships.doc(relId).collection('love_letters').orderBy('timestamp', descending: true).snapshots();
  Future<void> addLoveLetter(String relId, String title, String content) async {
    try {
      await _supabase.from('love_letters').insert({
        'relationship_id': relId,
        'sender_id': _currentUid ?? 'partner',
        'sender_name': 'Partner',
        'title': title,
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Supabase addLoveLetter notice: $e');
    }
    await _relationships.doc(relId).collection('love_letters').add({'title': title, 'content': content, 'senderId': _currentUid, 'senderName': 'Partner', 'timestamp': FieldValue.serverTimestamp()});
  }
  Future<void> deleteLoveLetter(String relId, String letterId) async {
    try {
      await _supabase.from('love_letters').delete().eq('id', letterId);
    } catch (_) {}
    await _relationships.doc(relId).collection('love_letters').doc(letterId).delete();
  }

  // --- RITUALS ---
  Stream<QuerySnapshot> streamRituals(String relId) => _relationships.doc(relId).collection('rituals').orderBy('order', descending: false).snapshots();
  Future<void> addRitual(String relId, String title, String icon) async {
    final order = DateTime.now().millisecondsSinceEpoch;
    try {
      await _supabase.from('rituals').insert({
        'relationship_id': relId,
        'title': title,
        'emoji': icon,
        'is_completed': false,
        'order': order,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Supabase addRitual notice: $e');
    }
    await _relationships.doc(relId).collection('rituals').add({
      'title': title,
      'emoji': icon,
      'u1Completed': false,
      'u2Completed': false,
      'lastCompleted': null,
      'order': order,
    });
  }
  Future<void> toggleRitual(String relId, String ritualId, bool isUser1, bool completed) async {
    try {
      await _supabase.from('rituals').update({
        'is_completed': completed,
      }).eq('id', ritualId);
    } catch (_) {}
    await _relationships.doc(relId).collection('rituals').doc(ritualId).update({
      isUser1 ? 'u1Completed' : 'u2Completed': completed,
      'lastCompleted': FieldValue.serverTimestamp(),
    });
  }

  // --- PRIVATE STICKY NOTES ---
  Stream<QuerySnapshot> streamWhisperNotes(String relId) => _relationships.doc(relId).collection('whisper_notes').orderBy('timestamp', descending: true).snapshots();
  Future<void> addWhisperNote(String relId, String content, String colorHex) async {
    await _relationships.doc(relId).collection('whisper_notes').add({
      'content': content,
      'color': colorHex,
      'authorUid': _currentUid,
      'posX': 0.5,
      'posY': 0.5,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
  Future<void> updateWhisperNotePosition(String relId, String noteId, double x, double y) async {
    await _relationships.doc(relId).collection('whisper_notes').doc(noteId).update({
      'posX': x,
      'posY': y,
    });
  }
  Future<void> deleteWhisperNote(String relId, String noteId) async => await _relationships.doc(relId).collection('whisper_notes').doc(noteId).delete();

  Stream<QuerySnapshot> streamSurprises(String relId) => _relationships.doc(relId).collection('surprise_messages').orderBy('unlockDate', descending: false).snapshots();
  Future<void> addSurprise(String relId, String title, String content, DateTime unlockDate, String? imageUrl) async {
    try {
      await _supabase.from('surprise_messages').insert({
        'relationship_id': relId,
        'sender_id': _currentUid ?? 'partner',
        'title': title,
        'content': content,
        'image_url': imageUrl,
        'unlock_date': unlockDate.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Supabase addSurprise notice: $e');
    }
    await _relationships.doc(relId).collection('surprise_messages').add({'title': title, 'content': content, 'unlockDate': Timestamp.fromDate(unlockDate), 'imageUrl': imageUrl, 'senderId': _currentUid, 'timestamp': FieldValue.serverTimestamp()});
  }
  Future<void> deleteSurprise(String relId, String surpriseId) async {
    try {
      await _supabase.from('surprise_messages').delete().eq('id', surpriseId);
    } catch (_) {}
    await _relationships.doc(relId).collection('surprise_messages').doc(surpriseId).delete();
  }

  // --- BUCKET LIST ---
  Stream<QuerySnapshot> streamBucketItems(String relId) => _relationships.doc(relId).collection('bucket_list').orderBy('timestamp', descending: true).snapshots();
  Future<void> addBucketItem(String relId, String title, String category) async {
    try {
      await _supabase.from('bucket_list').insert({
        'relationship_id': relId,
        'title': title,
        'category': category,
        'is_completed': false,
        'created_by': _currentUid,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Supabase addBucketItem notice: $e');
    }
    await _relationships.doc(relId).collection('bucket_list').add({'title': title, 'category': category, 'isCompleted': false, 'createdBy': _currentUid, 'timestamp': FieldValue.serverTimestamp()});
  }
  Future<void> toggleBucketItem(String relId, String itemId, bool completed) async {
    try {
      await _supabase.from('bucket_list').update({'is_completed': completed}).eq('id', itemId);
    } catch (_) {}
    await _relationships.doc(relId).collection('bucket_list').doc(itemId).update({'isCompleted': completed});
  }
  Future<void> deleteBucketItem(String relId, String itemId) async {
    try {
      await _supabase.from('bucket_list').delete().eq('id', itemId);
    } catch (_) {}
    await _relationships.doc(relId).collection('bucket_list').doc(itemId).delete();
  }

  // --- CALENDAR (0ms Reactive & Synced with Supabase) ---
  Stream<List<CalendarEventModel>> streamCalendarEvents(String relId) async* {
    if (_cachedEventsMap.containsKey(relId)) {
      yield _cachedEventsMap[relId]!;
    }
    _setupEventsListener(relId);
    yield* _getEventsController(relId).stream;
  }

  void _setupEventsListener(String relId) {
    if (_activeEventsListeners.contains(relId)) return;
    _activeEventsListeners.add(relId);

    Future<void> fetchAndEmit() async {
      try {
        final res = await _supabase
            .from('relationships')
            .select('data')
            .eq('id', relId)
            .maybeSingle();

        if (res != null && res['data'] is Map) {
          final data = res['data'] as Map;
          final rawEvents = data['calendarEvents'];
          if (rawEvents is List && rawEvents.isNotEmpty) {
            final events = rawEvents
                .whereType<Map>()
                .map((e) => CalendarEventModel.fromMap(Map<String, dynamic>.from(e)))
                .toList();
            events.sort((a, b) => a.date.compareTo(b.date));
            _cachedEventsMap[relId] = events;
            _getEventsController(relId).add(events);
            return;
          }
        }

        // Migration fallback: check Firestore calendar_events subcollection
        try {
          final snap = await _relationships
              .doc(relId)
              .collection('calendar_events')
              .orderBy('eventDate', descending: false)
              .get()
              .timeout(const Duration(seconds: 4));
          if (snap.docs.isNotEmpty) {
            final events = snap.docs.map((doc) {
              final d = doc.data();
              return CalendarEventModel.fromMap(d, id: doc.id);
            }).toList();
            _cachedEventsMap[relId] = events;
            _getEventsController(relId).add(events);

            // Persist migrated events to Supabase
            final eventsJson = events.map((e) => e.toMap()).toList();
            await _updateRelationshipData(relId, {'calendarEvents': eventsJson});
            return;
          }
        } catch (_) {}

        if (!_cachedEventsMap.containsKey(relId)) {
          _cachedEventsMap[relId] = [];
          _getEventsController(relId).add([]);
        }
      } catch (e) {
        debugPrint('fetch calendar events warning: $e');
        if (!_cachedEventsMap.containsKey(relId)) {
          _cachedEventsMap[relId] = [];
          _getEventsController(relId).add([]);
        }
      }
    }

    fetchAndEmit();
  }

  Future<void> addCalendarEvent(String relId, String title, DateTime date, String type, {String? notes}) async {
    final newEvent = CalendarEventModel(
      id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      date: date,
      type: type,
      notes: notes,
      createdBy: _currentUid,
      createdAt: DateTime.now(),
    );

    // 0ms INSTANT OPTIMISTIC EMISSION
    final currentList = List<CalendarEventModel>.from(_cachedEventsMap[relId] ?? []);
    currentList.add(newEvent);
    currentList.sort((a, b) => a.date.compareTo(b.date));
    _cachedEventsMap[relId] = currentList;
    _getEventsController(relId).add(currentList);

    // Update Supabase
    final eventsJson = currentList.map((e) => e.toMap()).toList();
    final updates = <String, dynamic>{
      'calendarEvents': eventsJson,
    };
    if (type == 'Reunion') {
      updates['nextMeetingDate'] = date;
    }
    await _updateRelationshipData(relId, updates);
  }

  Future<void> deleteCalendarEvent(String relId, String eventId) async {
    // 0ms INSTANT OPTIMISTIC REMOVAL
    final currentList = List<CalendarEventModel>.from(_cachedEventsMap[relId] ?? []);
    currentList.removeWhere((e) => e.id == eventId);
    _cachedEventsMap[relId] = currentList;
    _getEventsController(relId).add(currentList);

    // Update Supabase
    final eventsJson = currentList.map((e) => e.toMap()).toList();
    await _updateRelationshipData(relId, {'calendarEvents': eventsJson});
  }

  Future<void> updateNextMeetingDate(String relId, DateTime date) async {
    await _updateRelationshipData(relId, {'nextMeetingDate': date});
  }

  // --- STATS ---
  Future<void> incrementStat(String relId, String statKey) async {
    try {
      await _relationships.doc(relId).update({'stats.$statKey': FieldValue.increment(1)});
    } catch (_) {}
  }

  Future<void> setHeartSync(String relId, bool isUser1, bool isPressing) async {
    final field = isUser1 ? 'user1SyncPress' : 'user2SyncPress';
    await _updateRelationshipData(relId, {
      field: isPressing ? DateTime.now() : null,
    });
  }

  Future<void> updateChatBackground(String relId, int index) async {
    await _updateRelationshipData(relId, {
      'chatBackgroundIndex': index,
      'customChatBackgroundUrl': null, // Reset custom when selecting a preset
    });
  }

  Future<void> updateCustomChatBackground(String relId, File imageFile) async {
    if (_currentUid == null) return;
    
    // 1. Get current background to delete if exists
    final rel = await getRelationshipById(relId);
    final String? oldUrl = rel?.customChatBackgroundUrl;
    
    // 2. Upload new image
    final String fileName = 'chat_bg_${DateTime.now().millisecondsSinceEpoch}.jpg';
    String newUrl;
    try {
      final bytes = await imageFile.readAsBytes();
      await _supabase.storage.from('memories').uploadBinary(
        '$relId/backgrounds/$fileName',
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
      );
      newUrl = _supabase.storage.from('memories').getPublicUrl('$relId/backgrounds/$fileName');
    } catch (_) {
      final ref = _storage.ref().child('relationships/$relId/backgrounds/$fileName');
      final uploadTask = await ref.putFile(imageFile);
      newUrl = await uploadTask.ref.getDownloadURL();
    }

    // 3. Update Firestore & Supabase
    await _updateRelationshipData(relId, {
      'customChatBackgroundUrl': newUrl,
      'chatBackgroundIndex': -1, // Use -1 to indicate custom
    });

    // 4. Delete old file if exists
    if (oldUrl != null) {
      try {
        await _storage.refFromURL(oldUrl).delete();
      } catch (e) {
        print('Error deleting old chat background: $e');
      }
    }
  }

  Future<void> clearCustomChatBackground(String relId) async {
    final rel = await getRelationshipById(relId);
    final String? oldUrl = rel?.customChatBackgroundUrl;
    
    await _updateRelationshipData(relId, {
      'customChatBackgroundUrl': null,
      'chatBackgroundIndex': 0, // Reset to Minimal
    });

    if (oldUrl != null) {
      try {
        await _storage.refFromURL(oldUrl).delete();
      } catch (e) {
        print('Error deleting old chat background: $e');
      }
    }
  }

  Future<void> updateBiometricPreference(String relId, bool enabled) async {
    if (_currentUid == null) return;
    final rel = _cachedRelationship ?? await getRelationshipById(relId);
    final isUser1 = _currentUid == rel?.uid1;
    final field = isUser1 ? 'user1UseBiometrics' : 'user2UseBiometrics';
    await _updateRelationshipData(relId, {
      field: enabled,
      'useBiometrics': enabled,
    });
  }

  // --- PREMIUM ACTIVATION (NEW REAL FLOW) ---
  Future<void> activateRealPremium({
    required String relId,
    required String planType,
    required String transactionId,
    required DateTime renewalDate,
  }) async {
    if (_currentUid == null) return;

    // 1. Update the Relationship document
    await _updateRelationshipData(relId, {
      'isPlus': true,
      'premiumTransactionId': transactionId,
      'premiumRenewalDate': renewalDate,
      'premiumPlanType': planType,
      'premiumActivatedAt': DateTime.now(),
    });

    // 2. Best-effort user updates in Firestore
    try {
      final relDoc = await _relationships.doc(relId).get();
      final List<String> uids = List<String>.from(relDoc.get('uids') ?? []);
      
      final batch = _firestore.batch();
      for (var uid in uids) {
        batch.set(_users.doc(uid), {
          'isPlus': true,
          'premiumPlan': planType,
          'premiumExpiry': Timestamp.fromDate(renewalDate),
        }, SetOptions(merge: true));
        try {
          _supabase.from('users').update({
            'is_plus': true,
            'premium_plan': planType,
            'premium_expiry': renewalDate.toIso8601String(),
          }).eq('id', uid);
        } catch (_) {}
      }
      await batch.commit();
    } catch (_) {}

    await logActivity(relId, 'premium', 'NextMeet+ Sanctuary Activated! ✨ Welcome to Elite Love.');
    VibrationService.success();
  }

  // --- SUBSCRIPTION EXPIRY (DOWNGRADE) ---
  Future<void> downgradeToFree(String relId) async {
    if (_currentUid == null) return;

    // 1. Reset the Relationship document
    await _updateRelationshipData(relId, {
      'isPlus': false,
      'premiumRenewalDate': null,
      'premiumPlanType': null,
      'premiumTransactionId': null,
    });

    // 2. Best-effort user updates in Firestore & Supabase
    try {
      final relDoc = await _relationships.doc(relId).get();
      final List<String> uids = List<String>.from(relDoc.get('uids') ?? []);
      
      final batch = _firestore.batch();
      for (var uid in uids) {
        batch.update(_users.doc(uid), {
          'isPlus': false,
          'premiumPlan': null,
          'premiumExpiry': null,
        });
        try {
          _supabase.from('users').update({
            'is_plus': false,
            'premium_plan': null,
            'premium_expiry': null,
          }).eq('id', uid);
        } catch (_) {}
      }
      await batch.commit();
    } catch (_) {}

    await logActivity(relId, 'premium', 'Sanctuary Subscription Expired. Status Reset to Free. 🛡️');
    print('Relationship $relId downgraded to free tier.');
  }

  // --- MAP CUSTOMIZATION (Plus only) ---
  Future<void> updateMapSettings(String relId, {String? color, String? style}) async {
    final updates = <String, dynamic>{};
    if (color != null) updates['mapLineColor'] = color;
    if (style != null) updates['mapLineStyle'] = style;
    if (updates.isNotEmpty) {
      await _updateRelationshipData(relId, updates);
    }
  }

  // --- BATTERY STATUS ---
  Future<void> updateBatteryStatus(String relId, int level, bool isCharging) async {
    try {
      final rel = await getRelationshipById(relId);
      if (rel == null) return;
      final isUser1 = _currentUid == rel.uid1;
      await _updateRelationshipData(relId, {
        isUser1 ? 'user1Battery' : 'user2Battery': level,
        isUser1 ? 'user1IsCharging' : 'user2IsCharging': isCharging,
      });
    } catch (_) {}
  }

  // --- PASSWORD ---
  Future<void> updateUserPassword(String oldPassword, String newPassword) async {
    await _auth.updateUserPassword(oldPassword, newPassword);
  }

  // --- DAILY QUESTIONS FOR TWO ---
  Future<void> submitDailyAnswer(String relId, String dateKey, String questionText, String answerText) async {
    if (_currentUid == null) return;
    final rel = _cachedRelationship ?? await getRelationshipById(relId);
    if (rel == null) return;

    final currentMap = rel.toFirestoreMap();
    final rawDaily = currentMap['dailyAnswers'] is Map ? Map<String, dynamic>.from(currentMap['dailyAnswers'] as Map) : <String, dynamic>{};
    final dayEntry = rawDaily[dateKey] is Map ? Map<String, dynamic>.from(rawDaily[dateKey] as Map) : <String, dynamic>{
      'question': questionText,
      'answers': <String, dynamic>{},
    };
    final answers = dayEntry['answers'] is Map ? Map<String, dynamic>.from(dayEntry['answers'] as Map) : <String, dynamic>{};
    answers[_currentUid!] = {
      'text': answerText.trim(),
      'answeredAt': DateTime.now().toIso8601String(),
    };
    dayEntry['answers'] = answers;
    rawDaily[dateKey] = dayEntry;
    currentMap['dailyAnswers'] = rawDaily;

    // 0ms Optimistic local update
    final updatedRel = RelationshipModel.fromFirestore(currentMap, id: relId);
    _cachedRelationship = updatedRel;
    _relationshipStreamController.add(updatedRel);

    await _updateRelationshipData(relId, {
      'dailyAnswers': rawDaily,
    });
  }

  // --- DAILY SCRATCH LOVE NOTES ---
  Future<void> submitCustomScratchNote(String relId, String dateKey, String noteText) async {
    if (_currentUid == null) return;
    final rel = _cachedRelationship ?? await getRelationshipById(relId);
    if (rel == null) return;

    final currentMap = rel.toFirestoreMap();
    final scratchMap = currentMap['dailyScratchNotes'] is Map
        ? Map<String, dynamic>.from(currentMap['dailyScratchNotes'] as Map)
        : <String, dynamic>{};

    final dateEntry = scratchMap[dateKey] is Map
        ? Map<String, dynamic>.from(scratchMap[dateKey] as Map)
        : <String, dynamic>{};

    dateEntry[_currentUid!] = {
      'text': noteText.trim(),
      'authorName': rel.getMyName(_currentUid),
      'createdAt': DateTime.now().toIso8601String(),
    };

    scratchMap[dateKey] = dateEntry;
    currentMap['dailyScratchNotes'] = scratchMap;

    // 0ms Optimistic local update
    final updatedRel = RelationshipModel.fromFirestore(currentMap, id: relId);
    _cachedRelationship = updatedRel;
    _relationshipStreamController.add(updatedRel);

    await _updateRelationshipData(relId, {
      'dailyScratchNotes': scratchMap,
    });
  }
}
