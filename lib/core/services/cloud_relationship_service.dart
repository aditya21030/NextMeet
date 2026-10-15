import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/memory_model.dart';
import '../models/relationship_model.dart';
import 'notification_service.dart';
import 'vibration_service.dart';
import '../cities.dart';
import '../constants.dart';
import 'dart:convert';

class CloudRelationshipService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final NotificationService _notifications = NotificationService();

  // Collection References
  CollectionReference get _relationships => _firestore.collection('relationships');
  CollectionReference get _invites => _firestore.collection('invites');
  CollectionReference get _users => _firestore.collection('users');

  String? get currentUid => _auth.currentUser?.uid;
  String? get _currentUid => _auth.currentUser?.uid;

  // Upload a memory with image
  Future<void> addMemory(String relId, File image, String caption, String location, {bool isStory = false, double? lat, double? lng}) async {
    if (_currentUid == null) throw Exception('User not authenticated');
    
    // SECURITY: Enforce Memory limits
    final relDoc = await _relationships.doc(relId).get();
    if (!relDoc.exists) return;
    final isPlus = relDoc.get('isPlus') ?? false;
    final maxMemories = isPlus ? AppSubscription.plusMaxMemories : AppSubscription.freeMaxMemories;
    
    final memoriesCount = (await _relationships.doc(relId).collection('memories').count().get()).count ?? 0;
    if (memoriesCount >= maxMemories) {
      throw Exception('Memory limit reached. Upgrade to NextMeet+ for more space! ✨');
    }

    final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('relationships/$relId/memories/$fileName');
    
    final uploadTask = await ref.putFile(image);
    final String imageUrl = await uploadTask.ref.getDownloadURL();

    await _firestore.collection('relationships').doc(relId).collection('memories').add({
      'imageUrl': imageUrl,
      'caption': caption,
      'location': location,
      'date': FieldValue.serverTimestamp(),
      'addedBy': _currentUid,
      'isStory': isStory,
      'lat': lat,
      'lng': lng,
    });

    await logActivity(relId, 'memory', 'New ${isStory ? "Story" : "Moment"}: $location 📸');
    await incrementStat(relId, 'memories');
  }

  Future<String> uploadChatFile(String relId, File file, String type) async {
    if (_currentUid == null) throw Exception('User not authenticated');
    final String extension = type == 'voice' ? 'm4a' : 'jpg';
    final String fileName = 'chat_${type}_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final ref = _storage.ref().child('relationships/$relId/chat/$type/$fileName');
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<void> sendChatMessage(String relId, {
    String? text, 
    String? imageUrl, 
    String? voiceUrl, 
    String? stickerId,
    String type = 'text',
  }) async {
    if (_currentUid == null) return;
    await _firestore.collection('relationships').doc(relId).collection('messages').add({
      'senderUid': _currentUid,
      'text': text,
      'imageUrl': imageUrl,
      'voiceUrl': voiceUrl,
      'stickerId': stickerId,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
      'isSeen': false,
      'seenAt': null,
    });
    await updateActivity(relId);
    await incrementStat(relId, 'chat_messages');
  }

  Future<void> deleteChatMessage(String relId, String messageId) async {
    if (_currentUid == null) return;
    try {
      final doc = await _firestore.collection('relationships').doc(relId).collection('messages').doc(messageId).get();
      if (doc.exists) {
        final data = doc.data()!;
        final String? imageUrl = data['imageUrl'];
        final String? voiceUrl = data['voiceUrl'];
        if (imageUrl != null && imageUrl.isNotEmpty) {
          try { await _storage.refFromURL(imageUrl).delete(); } catch (_) {}
        }
        if (voiceUrl != null && voiceUrl.isNotEmpty) {
          try { await _storage.refFromURL(voiceUrl).delete(); } catch (_) {}
        }
      }
      await _firestore.collection('relationships').doc(relId).collection('messages').doc(messageId).delete();
    } catch (e) {
      print('Error in deleteChatMessage: $e');
    }
  }

  Future<void> updateActivity(String relId) async {
    if (_currentUid == null) return;
    final relationship = await _relationships.doc(relId).get();
    if (!relationship.exists) return;
    final isUser1 = _currentUid == relationship.get('uid1');
    await _relationships.doc(relId).update({
      isUser1 ? 'user1LastActive' : 'user2LastActive': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markMessagesAsSeen(String relId) async {
    if (_currentUid == null) return;
    final query = await _firestore.collection('relationships').doc(relId).collection('messages').where('isSeen', isEqualTo: false).get();
    final docsToUpdate = query.docs.where((doc) => doc['senderUid'] != _currentUid);
    if (docsToUpdate.isEmpty) return;
    final batch = _firestore.batch();
    for (var doc in docsToUpdate) {
      batch.update(doc.reference, {'isSeen': true, 'seenAt': FieldValue.serverTimestamp()});
    }
    await batch.commit();
  }

  Stream<int> streamUnreadCount(String relId) {
    if (_currentUid == null) return Stream.value(0);
    return _firestore.collection('relationships').doc(relId).collection('messages').where('isSeen', isEqualTo: false).snapshots().map((snapshot) {
      return snapshot.docs.where((doc) => doc['senderUid'] != _currentUid).length;
    });
  }

  Future<void> initNotifications(String relId) async {
    await _notifications.initialize();
    final token = await _notifications.getToken();
    if (token != null) await updateFcmToken(relId, token);
  }

  Future<void> updateFcmToken(String relId, String token) async {
    if (_currentUid == null) return;
    await _relationships.doc(relId).update({'userTokens.$_currentUid': token});
  }

  Stream<List<MemoryModel>> streamMemories(String relId) {
    return _firestore.collection('relationships').doc(relId).collection('memories').orderBy('date', descending: true).snapshots().map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data();
      if (data['date'] == null) data['date'] = Timestamp.now();
      return MemoryModel.fromFirestore(data, id: doc.id);
    }).toList());
  }

  Future<void> deleteMemory(String relId, String memoryId, String imageUrl) async {
    if (_currentUid == null) return;
    await _firestore.collection('relationships').doc(relId).collection('memories').doc(memoryId).delete();
    try { await _storage.refFromURL(imageUrl).delete(); } catch (_) {}
    await logActivity(relId, 'delete', 'A memory was removed 🗑️');
  }

  Future<void> updateMemoryCaptions(String relId, String memoryId, {String? caption, String? p1Caption, String? p2Caption}) async {
    if (_currentUid == null) return;
    Map<String, dynamic> updates = {};
    if (caption != null) updates['caption'] = caption;
    if (p1Caption != null) updates['partner1Caption'] = p1Caption;
    if (p2Caption != null) updates['partner2Caption'] = p2Caption;
    if (updates.isNotEmpty) await _firestore.collection('relationships').doc(relId).collection('memories').doc(memoryId).update(updates);
  }

  Future<String> createJourney(RelationshipModel localData) async {
    if (_currentUid == null) throw Exception('User not authenticated');
    final String code = (math.Random().nextInt(900000) + 100000).toString();
    final relDocRef = _relationships.doc();
    final relationship = localData.copyWith(id: relDocRef.id, uid1: _currentUid, uids: [_currentUid!], inviteCode: code, createdAt: DateTime.now(), status: 'waiting');
    await relDocRef.set(relationship.toFirestore());
    
    final userEmail = _auth.currentUser?.email ?? 'Unknown Email';
    await _invites.doc(code).set({
      'creatorUid': _currentUid, 
      'relationshipId': relDocRef.id, 
      'status': 'pending', 
      'createdAt': FieldValue.serverTimestamp(),
      'creatorEmail': userEmail
    });

    // Admin Dashboard Sync
    try {
      await _firestore.collection('pending_relationships').doc(relDocRef.id).set({
        'relId': relDocRef.id,
        'uid1': _currentUid,
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
      print('Error syncing createJourney to admin dashboard: $e');
    }
    
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
    }

    return joinedRelationship;
  }

  Future<RelationshipModel?> getRelationshipById(String relId) async {
    final doc = await _relationships.doc(relId).get();
    if (!doc.exists) return null;
    return RelationshipModel.fromFirestore(doc.data() as Map<String, dynamic>, id: doc.id);
  }

  Stream<RelationshipModel?> streamRelationship() {
    if (_currentUid == null) return Stream.value(null);
    return _relationships.where('uids', arrayContains: _currentUid).snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      // Deterministically prioritize an active relationship over an orphaned waiting document
      final activeDoc = snapshot.docs.cast<QueryDocumentSnapshot?>().firstWhere(
        (doc) => (doc?.data() as Map<String, dynamic>?)?['status'] == 'active',
        orElse: () => null,
      );
      final target = activeDoc ?? snapshot.docs.first;
      return RelationshipModel.fromFirestore(target.data() as Map<String, dynamic>, id: target.id);
    });
  }

  // --- TEMP SCRIPT FOR ADMIN / MIGRATION ---
  Future<void> syncOldAcceptedRelationships() async {
    try {
      final snapshot = await _firestore.collection('relationships').where('status', isEqualTo: 'active').get();
      final batch = _firestore.batch();
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final relId = doc.id;
        final uid1 = data['uid1'];
        final uid2 = data['uid2'];
        
        if (uid1 != null && uid2 != null) {
          final acceptedRef = _firestore.collection('accepted_relationships').doc(relId);
          batch.set(acceptedRef, {
            'relId': relId,
            'uid1': uid1,
            'uid2': uid2,
            'userName1': data['userName1'],
            'userName2': data['userName2'],
            'acceptedAt': data['createdAt'] ?? FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }
      
      final pendingSnap = await _firestore.collection('invites').where('status', isEqualTo: 'pending').get();
      for (var doc in pendingSnap.docs) {
        final data = doc.data();
        final code = doc.id;
        final relId = data['relationshipId'];
        final uid1 = data['creatorUid'];
        if (relId != null && uid1 != null) {
          // Fetch the relationship document to try to get the real username
          final relDoc = await _firestore.collection('relationships').doc(relId).get();
          final relData = relDoc.data();
          final userName1 = relData?['userName1'] ?? 'Unknown User';
          
          final pendingRef = _firestore.collection('pending_relationships').doc(relId);
          batch.set(pendingRef, {
            'relId': relId,
            'uid1': uid1,
            'userName1': userName1,
            'creatorEmail': data['creatorEmail'] ?? 'Old User (Email Unknown)',
            'inviteCode': code,
            'createdAt': data['createdAt'] ?? FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }
      
      await batch.commit();
      print('Successfully synced old relationships to accepted_relationships collection!');
    } catch (e) {
      print('Error syncing old relationships: $e');
      rethrow;
    }
  }

  Future<void> sendTouch(String relId, String type) async {
    if (_currentUid == null) return;
    await _relationships.doc(relId).update({'lastTouchType': type, 'lastTouchFrom': _currentUid, 'lastTouchTime': FieldValue.serverTimestamp()});
    String logTitle = 'Sent a "Touch" ❤️';
    if (type == 'miss') {
      logTitle = 'Sent a "Miss You" 🥺';
      // ignore: curly_braces_in_flow_control_structures
    } else if (type == 'hug') logTitle = 'Sent a "Digital Hug" 🤗';
    else if (type == 'emoji') logTitle = 'Sent a Reaction ✨';
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
    if (updates.isNotEmpty) await _relationships.doc(relId).update(updates);
  }

  Future<void> updateRelationshipDetails(String relId, Map<String, dynamic> updates) async {
    if (updates.isNotEmpty) {
      await _relationships.doc(relId).update(updates);
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
      await _relationships.doc(relId).update(updates);
    }
  }

  Future<void> logActivity(String relId, String type, String title, {String? detail}) async {
    if (_currentUid == null) return;
    await _relationships.doc(relId).collection('activities').add({'type': type, 'title': title, 'detail': detail, 'timestamp': FieldValue.serverTimestamp(), 'fromUid': _currentUid});
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
      await _relationships.doc(relId).update(updates);
      await logActivity(relId, 'update', 'Trip Details Updated ✈️');
    }
  }

  Future<void> updateTripExcitement(String relId, String uid, bool excited) async {
    await _relationships.doc(relId).update({'tripExcitement.$uid': excited});
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
    await _relationships.doc(relId).update({'tripDestination': FieldValue.delete(), 'tripDate': FieldValue.delete(), 'tripBudget': FieldValue.delete(), 'tripNotes': FieldValue.delete(), 'tripAccommodation': FieldValue.delete(), 'tripTransport': FieldValue.delete(), 'tripMustSee': FieldValue.delete(), 'tripMood': FieldValue.delete(), 'tripStory': FieldValue.delete(), 'tripExcitement': FieldValue.delete()});
    for (final coll in ['tasks', 'packing_list', 'expenses', 'itinerary']) {
      final docs = await _relationships.doc(relId).collection(coll).get();
      for (final doc in docs.docs) {
        await doc.reference.delete();
      }
    }
    await logActivity(relId, 'update', 'Trip Reset/Deleted 🗑️');
  }

  // --- PROFILE ---
  Future<void> updateProfile(String relId, {String? name1, String? loc1, String? photo1, String? nick1, double? lat1, double? lng1, String? name2, String? loc2, String? photo2, String? nick2, double? lat2, double? lng2}) async {
    final updates = <String, dynamic>{};
    if (name1 != null) updates['userName1'] = name1; if (loc1 != null) updates['userLocation1'] = loc1; if (photo1 != null) updates['userPhoto1'] = photo1; if (nick1 != null) updates['user1PartnerNickname'] = nick1; if (lat1 != null) updates['user1Lat'] = lat1; if (lng1 != null) updates['user1Lng'] = lng1;
    if (name2 != null) updates['userName2'] = name2; if (loc2 != null) updates['userLocation2'] = loc2; if (photo2 != null) updates['userPhoto2'] = photo2; if (nick2 != null) updates['user2PartnerNickname'] = nick2; if (lat2 != null) updates['user2Lat'] = lat2; if (lng2 != null) updates['user2Lng'] = lng2;
    if (updates.isNotEmpty) await _relationships.doc(relId).update(updates);
  }

  Future<String> uploadProfilePhoto(String relId, Uint8List imageBytes) async {
    final String fileName = 'profile_${_currentUid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    
    if (imageBytes.isEmpty) {
      throw Exception('Image bytes are empty! Scoped storage issue.');
    }
    
    try {
      final ref = _storage.ref().child('relationships/$relId/profiles/$fileName');
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final uploadTask = await ref.putData(imageBytes, metadata);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Firebase Storage Error: $e');
    }
  }

  // --- PRIVATE SPACE ---
  Future<void> updatePrivateSpacePin(String relId, String? pin) async => await _relationships.doc(relId).update({'privateSpacePin': pin});
  Future<void> updatePrivateSpaceTimeout(String relId, String timeout) async => await _relationships.doc(relId).update({'privateSpaceTimeout': timeout});
  Future<void> requestPinReset(String relId) async => await _relationships.doc(relId).update({'pinResetRequestBy': _currentUid, 'pinResetRequestAt': FieldValue.serverTimestamp(), 'pinResetApproved': false});
  Future<void> approvePinReset(String relId) async => await _relationships.doc(relId).update({'pinResetApproved': true});
  Future<void> finalizePinReset(String relId, String newPin) async => await _relationships.doc(relId).update({'privateSpacePin': newPin, 'pinResetRequestBy': null, 'pinResetRequestAt': null, 'pinResetApproved': false});
  Future<void> cancelPinReset(String relId) async => await _relationships.doc(relId).update({'pinResetRequestBy': null, 'pinResetRequestAt': null, 'pinResetApproved': false});
  Future<void> generatePinResetOtps(String relId) async {
    final otp1 = (100000 + math.Random().nextInt(900000)).toString();
    final otp2 = (100000 + math.Random().nextInt(900000)).toString();
    await _relationships.doc(relId).update({'pinResetOtp1': otp1, 'pinResetOtp2': otp2, 'pinResetOtpExpiry': Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 15)))});
  }
  Future<bool> verifyPinResetOtps(String relId, String otp1, String otp2) async {
    final doc = await _relationships.doc(relId).get();
    final data = doc.data() as Map<String, dynamic>;
    if (data['pinResetOtp1'] == otp1 && data['pinResetOtp2'] == otp2) { await approvePinReset(relId); return true; }
    return false;
  }

  // --- PRIVATE SPACE / ELITE TOOLS ---
  Future<void> updateSanctuaryPresence(String relId, bool isIn) async {
    if (_currentUid == null) return;
    final rel = await _relationships.doc(relId).get();
    if (!rel.exists) return;
    final isUser1 = _currentUid == rel.get('uid1');
    await _relationships.doc(relId).update({
      isUser1 ? 'u1InSanctuary' : 'u2InSanctuary': isIn,
      isUser1 ? 'u1SanctuaryLastSeen' : 'u2SanctuaryLastSeen': FieldValue.serverTimestamp(),
    });
  }
  
  Future<void> updateSanctuaryStatus(bool isIn) async {
    if (_currentUid == null) return;
    final rels = await _relationships.where('uids', arrayContains: _currentUid).limit(1).get();
    if (rels.docs.isEmpty) return;
    await updateSanctuaryPresence(rels.docs.first.id, isIn);
  }

  Future<void> updateSketchpadData(String relId, String? data) async {
    if (_currentUid == null) return;
    await _relationships.doc(relId).update({
      'sketchpadData': data,
      'sketchpadLastUpdate': FieldValue.serverTimestamp(),
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
    await _relationships.doc(relId).collection('private_photos').add({'url': url, 'sizeBytes': size, 'timestamp': FieldValue.serverTimestamp()});
    await _relationships.doc(relId).update({'privateSpaceStorageBytes': FieldValue.increment(size)});
  }
  Future<void> deletePrivatePhoto(String relId, String photoId, String url, int size) async {
    await _relationships.doc(relId).collection('private_photos').doc(photoId).delete();
    try { await _storage.refFromURL(url).delete(); } catch (_) {}
    await _relationships.doc(relId).update({'privateSpaceStorageBytes': FieldValue.increment(-size)});
  }

  Stream<QuerySnapshot> streamPrivateNotes(String relId) => _relationships.doc(relId).collection('private_notes').orderBy('timestamp', descending: true).snapshots();
  Future<void> addPrivateNote(String relId, String title, String content, String category) async => await _relationships.doc(relId).collection('private_notes').add({'title': title, 'content': content, 'category': category, 'createdBy': _currentUid, 'timestamp': FieldValue.serverTimestamp()});
  Future<void> deletePrivateNote(String relId, String noteId) async => await _relationships.doc(relId).collection('private_notes').doc(noteId).delete();

  Stream<QuerySnapshot> streamLoveLetters(String relId) => _relationships.doc(relId).collection('love_letters').orderBy('timestamp', descending: true).snapshots();
  Future<void> addLoveLetter(String relId, String title, String content) async => await _relationships.doc(relId).collection('love_letters').add({'title': title, 'content': content, 'senderId': _currentUid, 'senderName': 'Partner', 'timestamp': FieldValue.serverTimestamp()});
  Future<void> deleteLoveLetter(String relId, String letterId) async => await _relationships.doc(relId).collection('love_letters').doc(letterId).delete();

  // --- RITUALS ---
  Stream<QuerySnapshot> streamRituals(String relId) => _relationships.doc(relId).collection('rituals').orderBy('order', descending: false).snapshots();
  Future<void> addRitual(String relId, String title, String icon) async {
    await _relationships.doc(relId).collection('rituals').add({
      'title': title,
      'emoji': icon,
      'u1Completed': false,
      'u2Completed': false,
      'lastCompleted': null,
      'order': DateTime.now().millisecondsSinceEpoch,
    });
  }
  Future<void> toggleRitual(String relId, String ritualId, bool isUser1, bool completed) async {
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
      'posX': 0.5, // 0.0 to 1.0 (relative to container width)
      'posY': 0.5, // 0.0 to 1.0 (relative to container height)
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
  Future<void> addSurprise(String relId, String title, String content, DateTime unlockDate, String? imageUrl) async => await _relationships.doc(relId).collection('surprise_messages').add({'title': title, 'content': content, 'unlockDate': Timestamp.fromDate(unlockDate), 'imageUrl': imageUrl, 'senderId': _currentUid, 'timestamp': FieldValue.serverTimestamp()});
  Future<void> deleteSurprise(String relId, String surpriseId) async => await _relationships.doc(relId).collection('surprise_messages').doc(surpriseId).delete();

  // --- BUCKET LIST ---
  Stream<QuerySnapshot> streamBucketItems(String relId) => _relationships.doc(relId).collection('bucket_list').orderBy('timestamp', descending: true).snapshots();
  Future<void> addBucketItem(String relId, String title, String category) async => await _relationships.doc(relId).collection('bucket_list').add({'title': title, 'category': category, 'isCompleted': false, 'createdBy': _currentUid, 'timestamp': FieldValue.serverTimestamp()});
  Future<void> toggleBucketItem(String relId, String itemId, bool completed) async => await _relationships.doc(relId).collection('bucket_list').doc(itemId).update({'isCompleted': completed});
  Future<void> deleteBucketItem(String relId, String itemId) async => await _relationships.doc(relId).collection('bucket_list').doc(itemId).delete();

  // --- CALENDAR ---
  Stream<QuerySnapshot> streamCalendarEvents(String relId) => _relationships.doc(relId).collection('calendar_events').orderBy('eventDate', descending: false).snapshots();
  Future<void> addCalendarEvent(String relId, String title, DateTime date, String type) async => await _relationships.doc(relId).collection('calendar_events').add({'title': title, 'eventDate': Timestamp.fromDate(date), 'type': type, 'createdBy': _currentUid, 'timestamp': FieldValue.serverTimestamp()});
  Future<void> deleteCalendarEvent(String relId, String eventId) async => await _relationships.doc(relId).collection('calendar_events').doc(eventId).delete();

  // --- STATS ---
  Future<void> incrementStat(String relId, String statKey) async => await _relationships.doc(relId).update({'stats.$statKey': FieldValue.increment(1)});

  Future<void> setHeartSync(String relId, bool isUser1, bool isPressing) async {
    final field = isUser1 ? 'user1SyncPress' : 'user2SyncPress';
    await _relationships.doc(relId).update({
      field: isPressing ? FieldValue.serverTimestamp() : null,
    });
  }

  Future<void> updateChatBackground(String relId, int index) async {
    await _relationships.doc(relId).update({
      'chatBackgroundIndex': index,
      'customChatBackgroundUrl': null, // Reset custom when selecting a preset
    });
  }

  Future<void> updateCustomChatBackground(String relId, File imageFile) async {
    if (_currentUid == null) return;
    
    // 1. Get current background to delete if exists
    final doc = await _relationships.doc(relId).get();
    final data = doc.data() as Map<String, dynamic>?;
    final String? oldUrl = data?['customChatBackgroundUrl'];
    
    // 2. Upload new image
    final String fileName = 'chat_bg_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('relationships/$relId/backgrounds/$fileName');
    final uploadTask = await ref.putFile(imageFile);
    final String newUrl = await uploadTask.ref.getDownloadURL();

    // 3. Update Firestore
    await _relationships.doc(relId).update({
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
    final doc = await _relationships.doc(relId).get();
    final data = doc.data() as Map<String, dynamic>?;
    final String? oldUrl = data?['customChatBackgroundUrl'];
    
    await _relationships.doc(relId).update({
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
    await _relationships.doc(relId).update({'useBiometrics': enabled});
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
    await _relationships.doc(relId).update({
      'isPlus': true,
      'premiumTransactionId': transactionId,
      'premiumRenewalDate': Timestamp.fromDate(renewalDate),
      'premiumPlanType': planType,
      'premiumActivatedAt': FieldValue.serverTimestamp(),
    });

    // 2. Update both users in the relationship (Portability)
    final relDoc = await _relationships.doc(relId).get();
    final List<String> uids = List<String>.from(relDoc.get('uids') ?? []);
    
    final batch = _firestore.batch();
    for (var uid in uids) {
      batch.set(_users.doc(uid), {
        'isPlus': true,
        'premiumPlan': planType,
        'premiumExpiry': Timestamp.fromDate(renewalDate),
      }, SetOptions(merge: true));
    }
    await batch.commit();

    await logActivity(relId, 'premium', 'NextMeet+ Sanctuary Activated! ✨ Welcome to Elite Love.');
    VibrationService.success();
  }

  // --- SUBSCRIPTION EXPIRY (DOWNGRADE) ---
  Future<void> downgradeToFree(String relId) async {
    if (_currentUid == null) return;

    // 1. Reset the Relationship document
    await _relationships.doc(relId).update({
      'isPlus': false,
      'premiumRenewalDate': null,
      'premiumPlanType': null,
      'premiumTransactionId': null,
    });

    // 2. Reset the User documents (Portability)
    final relDoc = await _relationships.doc(relId).get();
    final List<String> uids = List<String>.from(relDoc.get('uids') ?? []);
    
    final batch = _firestore.batch();
    for (var uid in uids) {
      batch.update(_users.doc(uid), {
        'isPlus': false,
        'premiumPlan': null,
        'premiumExpiry': null,
      });
    }
    await batch.commit();

    await logActivity(relId, 'premium', 'Sanctuary Subscription Expired. Status Reset to Free. 🛡️');
    print('Relationship $relId downgraded to free tier.');
  }

  // --- MAP CUSTOMIZATION (Plus only) ---
  Future<void> updateMapSettings(String relId, {String? color, String? style}) async {
    final updates = <String, dynamic>{};
    if (color != null) updates['mapLineColor'] = color;
    if (style != null) updates['mapLineStyle'] = style;
    if (updates.isNotEmpty) {
      await _relationships.doc(relId).update(updates);
    }
  }

  // --- BATTERY STATUS ---
  Future<void> updateBatteryStatus(String relId, int level, bool isCharging) async {
    final relDoc = await _relationships.doc(relId).get();
    if (!relDoc.exists) return;
    
    final isUser1 = _currentUid == relDoc.get('uid1');
    await _relationships.doc(relId).update({
      isUser1 ? 'user1Battery' : 'user2Battery': level,
      isUser1 ? 'user1IsCharging' : 'user2IsCharging': isCharging,
    });
  }

  // --- PASSWORD ---
  Future<void> updateUserPassword(String oldPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) throw Exception('User not authenticated');
    AuthCredential credential = EmailAuthProvider.credential(email: user.email!, password: oldPassword);
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }
}
