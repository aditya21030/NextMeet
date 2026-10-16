import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../cities.dart';

class RelationshipModel {
  final String? id; // Firestore Document ID
  final String? uid1;
  final String? uid2;
  final List<String> uids;
  final String? inviteCode;
  final DateTime? createdAt;
  
  // Profile Data
  final String? userName1;
  final String? userName2;
  final String? userLocation1;
  final String? userLocation2;
  final String? userMood1;
  final String? userMood2;
  final String? userPhoto1;
  final String? userPhoto2;
  final String? user1PartnerNickname; // User 1's nickname for User 2
  final String? user2PartnerNickname; // User 2's nickname for User 1
  final String? partnerFcmToken;
  
  // Coordinates for distance calculation
  final double? user1Lat;
  final double? user1Lng;
  final double? user2Lat;
  final double? user2Lng;

  // Timezone & Battery data
  final int? user1TimezoneOffset; // Minutes from UTC
  final int? user2TimezoneOffset;
  final int? user1Battery;
  final int? user2Battery;
  final bool? user1IsCharging;
  final bool? user2IsCharging;
  
  // Interaction/Real-time
  final String? lastTouchType;
  final String? lastTouchFrom;
  final DateTime? lastTouchTime;
  final Map<String, String>? userTokens;
  
  // New Streak Tracking
  final DateTime? user1LastActive;
  final DateTime? user2LastActive;
  final int streakCount;
  final int streakShields;
  final DateTime? lastStreakIncrement;
  
  // Heart Sync Interaction
  final DateTime? user1SyncPress;
  final DateTime? user2SyncPress;
  
  // Relationship stats/Settings
  final DateTime anniversaryDate;
  final DateTime nextMeetingDate;
  final DateTime lastMeetingDate;
  final double distanceKm;
  final String loveQuote;
  
  // Trip Planner
  final String? tripDestination;
  final DateTime? tripDate;
  final DateTime? tripEndDate;
  final double? tripBudget;
  final String? tripNotes;
  final String? tripAccommodation;
  final String? tripTransport;
  final String? tripMustSee;
  final String? tripMood;
  final String? tripStory;
  final Map<String, bool> tripExcitement;
  
  // Private Space Settings
  final String? privateSpacePin;
  final String privateSpaceTimeout;
  final int privateSpaceStorageBytes;
  
  // Premium Status
  final bool isPlus;
  
  // PIN Reset Request Flow
  final String? pinResetRequestBy;
  final DateTime? pinResetRequestAt;
  final bool pinResetApproved;
  final DateTime? pinResetOtpExpiry;
  final String? pinResetOtp1;
  final String? pinResetOtp2;
  
  // Premium Subscription & Chat Details
  final int chatBackgroundIndex; // 0: Default, 1: Starry, etc.
  final String? premiumTransactionId;
  final DateTime? premiumRenewalDate;
  final String? premiumPlanType; // 'Monthly' or 'Annual'
  final bool useBiometrics; // Plus only
  final String? hapticPatternType; // 'Heartbeat', 'Warm Hug', 'Digital Touch'
  final String? mapLineColor; // Hex string for map path (Plus only)
  final String? mapLineStyle; // 'Neon', 'Solid', 'Dotted'
  
  // Sanctum Elite Presence
  final bool u1InSanctuary;
  final bool u2InSanctuary;
  final DateTime? u1SanctuaryLastSeen;
  final DateTime? u2SanctuaryLastSeen;
  
  // New: Global Statistics for Achievements
  final Map<String, int> stats;
  final String? customChatBackgroundUrl; // Premium: Custom chat wallpaper
  final String status; // 'waiting' or 'active'

  RelationshipModel({
    this.id,
    this.uid1,
    this.uid2,
    this.uids = const [],
    this.inviteCode,
    this.createdAt,
    this.userName1,
    this.userName2,
    this.userLocation1,
    this.userLocation2,
    this.userMood1,
    this.userMood2,
    this.userPhoto1,
    this.userPhoto2,
    this.user1PartnerNickname,
    this.user2PartnerNickname,
    this.partnerFcmToken,
    this.lastTouchType,
    this.lastTouchFrom,
    this.lastTouchTime,
    this.userTokens,
    required this.anniversaryDate,
    required this.nextMeetingDate,
    required this.lastMeetingDate,
    required this.distanceKm,
    required this.loveQuote,
    this.tripDestination,
    this.tripDate,
    this.tripEndDate,
    this.tripBudget,
    this.tripNotes,
    this.tripAccommodation,
    this.tripTransport,
    this.tripMustSee,
    this.tripMood = 'Chill',
    this.tripStory,
    this.tripExcitement = const {},
    this.privateSpacePin,
    this.privateSpaceTimeout = 'After 5 Minutes',
    this.privateSpaceStorageBytes = 0,
    this.user1LastActive,
    this.user2LastActive,
    this.streakCount = 0,
    this.streakShields = 0,
    this.lastStreakIncrement,
    this.isPlus = false,
    this.user1SyncPress,
    this.user2SyncPress,
    this.user1Lat,
    this.user1Lng,
    this.user2Lat,
    this.user2Lng,
    this.user1TimezoneOffset,
    this.user2TimezoneOffset,
    this.user1Battery,
    this.user2Battery,
    this.user1IsCharging,
    this.user2IsCharging,
    this.pinResetRequestBy,
    this.pinResetRequestAt,
    this.pinResetApproved = false,
    this.pinResetOtp1,
    this.pinResetOtp2,
    this.pinResetOtpExpiry,
    this.chatBackgroundIndex = 0,
    this.premiumTransactionId,
    this.premiumRenewalDate,
    this.premiumPlanType,
    this.useBiometrics = false,
    this.hapticPatternType = 'Standard',
    this.mapLineColor,
    this.mapLineStyle = 'Neon',
    this.stats = const {},
    this.u1InSanctuary = false,
    this.u2InSanctuary = false,
    this.u1SanctuaryLastSeen,
    this.u2SanctuaryLastSeen,
    this.customChatBackgroundUrl,
    this.status = 'active',
  });

  // User-aware helper methods
  String getMyName(String? currentUid) => currentUid == uid1 ? (userName1 ?? 'You') : (userName2 ?? 'You');
  String getMyRealName(String? currentUid) => currentUid == uid1 ? (userName1 ?? '') : (userName2 ?? '');
  String getPartnerRealName(String? currentUid) => currentUid == uid1 ? (userName2 ?? '') : (userName1 ?? '');

  String getMyPetName(String? currentUid) => currentUid == uid1 ? (user2PartnerNickname ?? '') : (user1PartnerNickname ?? '');
  String getPartnerPetName(String? currentUid) => currentUid == uid1 ? (user1PartnerNickname ?? '') : (user2PartnerNickname ?? '');

  String getDisplayPartnerName(String? currentUid) {
    final petName = getPartnerPetName(currentUid);
    if (petName.isNotEmpty) return petName;
    return getPartnerRealName(currentUid).isNotEmpty ? getPartnerRealName(currentUid) : 'Partner';
  }

  String getDisplayMyName(String? currentUid) {
    final realName = getMyRealName(currentUid);
    if (realName.isNotEmpty) return realName;
    return 'You';
  }

  String? getPartnerUid(String? currentUid) => currentUid == uid1 ? uid2 : uid1;
  String getMyMood(String? currentUid) => currentUid == uid1 ? (userMood1 ?? 'Happy 💖') : (userMood2 ?? 'Happy 💖');
  String getPartnerMood(String? currentUid) => currentUid == uid1 ? (userMood2 ?? 'Missing You 🥺') : (userMood1 ?? 'Missing You 🥺');

  String getMyLocation(String? currentUid) => currentUid == uid1 ? (userLocation1 ?? '') : (userLocation2 ?? '');
  String getPartnerLocation(String? currentUid) => currentUid == uid1 ? (userLocation2 ?? '') : (userLocation1 ?? '');

  String getMyPhoto(String? currentUid) => currentUid == uid1 ? (userPhoto1 ?? '') : (userPhoto2 ?? '');
  String getPartnerPhoto(String? currentUid) => currentUid == uid1 ? (userPhoto2 ?? '') : (userPhoto1 ?? '');

  bool isPartnerPressing(String? currentUid) {
    final partnerPress = currentUid == uid1 ? user2SyncPress : user1SyncPress;
    if (partnerPress == null) return false;
    return DateTime.now().difference(partnerPress).inSeconds < 8;
  }

  bool isMyPressing(String? currentUid) {
    final myPress = currentUid == uid1 ? user1SyncPress : user2SyncPress;
    if (myPress == null) return false;
    return DateTime.now().difference(myPress).inSeconds < 8;
  }

  bool isHeartSynced(String? currentUid) {
    return isMyPressing(currentUid) && isPartnerPressing(currentUid);
  }

  double get computedDistance {
    if (user1Lat == null || user1Lng == null || user2Lat == null || user2Lng == null ||
        user1Lat == 0.0 || user1Lng == 0.0 || user2Lat == 0.0 || user2Lng == 0.0) {
      return distanceKm;
    }
    return CityData.calculateDistance(user1Lat!, user1Lng!, user2Lat!, user2Lng!);
  }

  String get widgetDistance {
    final dist = computedDistance;
    if (dist <= 0) return "0";
    return dist.toStringAsFixed(1);
  }

  String get formattedDistance {
    final dist = computedDistance;
    if (dist <= 0) return "Right Here ❤️";
    return "${dist.toStringAsFixed(1)} KM Away";
  }

  static DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    if (val is DateTime) return val;
    if (val is String) return DateTime.tryParse(val);
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    return null;
  }

  factory RelationshipModel.fromFirestore(Map<String, dynamic> map, {String? id}) {
    return RelationshipModel(
      id: id,
      uid1: map['uid1'],
      uid2: map['uid2'],
      uids: map['uids'] != null ? List<String>.from(map['uids']) : [],
      inviteCode: map['inviteCode'],
      createdAt: _parseDate(map['createdAt']),
      userName1: map['userName1'],
      userName2: map['userName2'],
      userLocation1: map['userLocation1'],
      userLocation2: map['userLocation2'],
      userMood1: map['userMood1'],
      userMood2: map['userMood2'],
      userPhoto1: map['userPhoto1'],
      userPhoto2: map['userPhoto2'],
      user1PartnerNickname: map['user1PartnerNickname'],
      user2PartnerNickname: map['user2PartnerNickname'],
      partnerFcmToken: map['partnerFcmToken'],
      lastTouchType: map['lastTouchType'],
      lastTouchFrom: map['lastTouchFrom'],
      lastTouchTime: _parseDate(map['lastTouchTime']),
      userTokens: map['userTokens'] != null ? Map<String, String>.from(map['userTokens']) : null,
      anniversaryDate: _parseDate(map['anniversaryDate']) ?? DateTime.now(),
      nextMeetingDate: _parseDate(map['nextMeetingDate']) ?? DateTime.now().add(const Duration(days: 30)),
      lastMeetingDate: _parseDate(map['lastMeetingDate']) ?? DateTime.now().subtract(const Duration(days: 7)),
      distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 0.0,
      loveQuote: map['loveQuote'] ?? 'Every day apart is one day closer ❤️',
      tripDestination: map['tripDestination'],
      tripDate: _parseDate(map['tripDate']),
      tripEndDate: _parseDate(map['tripEndDate']),
      tripBudget: (map['tripBudget'] as num?)?.toDouble(),
      tripNotes: map['tripNotes'],
      tripAccommodation: map['tripAccommodation'],
      tripTransport: map['tripTransport'],
      tripMustSee: map['tripMustSee'],
      tripMood: map['tripMood'] ?? 'Chill',
      tripStory: map['tripStory'],
      tripExcitement: map['tripExcitement'] != null ? Map<String, bool>.from(map['tripExcitement']) : {},
      privateSpacePin: map['privateSpacePin'],
      privateSpaceTimeout: map['privateSpaceTimeout'] ?? 'After 5 Minutes',
      privateSpaceStorageBytes: map['privateSpaceStorageBytes'] ?? 0,
      user1LastActive: _parseDate(map['user1LastActive']),
      user2LastActive: _parseDate(map['user2LastActive']),
      streakCount: map['streakCount'] ?? 0,
      streakShields: map['streakShields'] ?? 0,
      lastStreakIncrement: _parseDate(map['lastStreakIncrement']),
      isPlus: map['isPlus'] ?? false,
      user1SyncPress: _parseDate(map['user1SyncPress']),
      user2SyncPress: _parseDate(map['user2SyncPress']),
      user1Lat: (map['user1Lat'] as num?)?.toDouble(),
      user1Lng: (map['user1Lng'] as num?)?.toDouble(),
      user2Lat: (map['user2Lat'] as num?)?.toDouble(),
      user2Lng: (map['user2Lng'] as num?)?.toDouble(),
      user1TimezoneOffset: map['user1TimezoneOffset'] as int?,
      user2TimezoneOffset: map['user2TimezoneOffset'] as int?,
      user1Battery: map['user1Battery'] as int?,
      user2Battery: map['user2Battery'] as int?,
      user1IsCharging: map['user1IsCharging'] as bool?,
      user2IsCharging: map['user2IsCharging'] as bool?,
      pinResetRequestBy: map['pinResetRequestBy'],
      pinResetRequestAt: _parseDate(map['pinResetRequestAt']),
      pinResetApproved: map['pinResetApproved'] ?? false,
      pinResetOtp1: map['pinResetOtp1'],
      pinResetOtp2: map['pinResetOtp2'],
      pinResetOtpExpiry: _parseDate(map['pinResetOtpExpiry']),
      chatBackgroundIndex: map['chatBackgroundIndex'] ?? 0,
      premiumTransactionId: map['premiumTransactionId'],
      premiumRenewalDate: _parseDate(map['premiumRenewalDate']),
      premiumPlanType: map['premiumPlanType'],
      useBiometrics: map['useBiometrics'] ?? false,
      hapticPatternType: map['hapticPatternType'] ?? 'Standard',
      mapLineColor: map['mapLineColor'],
      mapLineStyle: map['mapLineStyle'] ?? 'Neon',
      stats: map['stats'] != null ? Map<String, int>.from(map['stats']) : {},
      u1InSanctuary: map['u1InSanctuary'] ?? false,
      u2InSanctuary: map['u2InSanctuary'] ?? false,
      u1SanctuaryLastSeen: _parseDate(map['u1SanctuaryLastSeen']),
      u2SanctuaryLastSeen: _parseDate(map['u2SanctuaryLastSeen']),
      customChatBackgroundUrl: map['customChatBackgroundUrl'],
      status: map['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid1': uid1,
      'uid2': uid2,
      'uids': uids,
      'inviteCode': inviteCode,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'userName1': userName1,
      'userName2': userName2,
      'userLocation1': userLocation1,
      'userLocation2': userLocation2,
      'userMood1': userMood1,
      'userMood2': userMood2,
      'userPhoto1': userPhoto1,
      'userPhoto2': userPhoto2,
      'user1PartnerNickname': user1PartnerNickname,
      'user2PartnerNickname': user2PartnerNickname,
      'partnerFcmToken': partnerFcmToken,
      'lastTouchType': lastTouchType,
      'lastTouchFrom': lastTouchFrom,
      'lastTouchTime': lastTouchTime != null ? Timestamp.fromDate(lastTouchTime!) : null,
      'userTokens': userTokens,
      'anniversaryDate': Timestamp.fromDate(anniversaryDate),
      'nextMeetingDate': Timestamp.fromDate(nextMeetingDate),
      'lastMeetingDate': Timestamp.fromDate(lastMeetingDate),
      'distanceKm': distanceKm,
      'loveQuote': loveQuote,
      'tripDestination': tripDestination,
      'tripDate': tripDate != null ? Timestamp.fromDate(tripDate!) : null,
      'tripEndDate': tripEndDate != null ? Timestamp.fromDate(tripEndDate!) : null,
      'tripBudget': tripBudget,
      'tripNotes': tripNotes,
      'tripAccommodation': tripAccommodation,
      'tripTransport': tripTransport,
      'tripMustSee': tripMustSee,
      'tripMood': tripMood,
      'tripStory': tripStory,
      'tripExcitement': tripExcitement,
      'privateSpacePin': privateSpacePin,
      'privateSpaceTimeout': privateSpaceTimeout,
      'privateSpaceStorageBytes': privateSpaceStorageBytes,
      'user1LastActive': user1LastActive != null ? Timestamp.fromDate(user1LastActive!) : null,
      'user2LastActive': user2LastActive != null ? Timestamp.fromDate(user2LastActive!) : null,
      'streakCount': streakCount,
      'streakShields': streakShields,
      'lastStreakIncrement': lastStreakIncrement != null ? Timestamp.fromDate(lastStreakIncrement!) : null,
      'isPlus': isPlus,
      'user1SyncPress': user1SyncPress != null ? Timestamp.fromDate(user1SyncPress!) : null,
      'user2SyncPress': user2SyncPress != null ? Timestamp.fromDate(user2SyncPress!) : null,
      'user1Lat': user1Lat,
      'user1Lng': user1Lng,
      'user2Lat': user2Lat,
      'user2Lng': user2Lng,
      'user1TimezoneOffset': user1TimezoneOffset,
      'user2TimezoneOffset': user2TimezoneOffset,
      'user1Battery': user1Battery,
      'user2Battery': user2Battery,
      'user1IsCharging': user1IsCharging,
      'user2IsCharging': user2IsCharging,
      'pinResetRequestBy': pinResetRequestBy,
      'pinResetRequestAt': pinResetRequestAt != null ? Timestamp.fromDate(pinResetRequestAt!) : null,
      'pinResetApproved': pinResetApproved,
      'pinResetOtp1': pinResetOtp1,
      'pinResetOtp2': pinResetOtp2,
      'pinResetOtpExpiry': pinResetOtpExpiry != null ? Timestamp.fromDate(pinResetOtpExpiry!) : null,
      'chatBackgroundIndex': chatBackgroundIndex,
      'premiumTransactionId': premiumTransactionId,
      'premiumRenewalDate': premiumRenewalDate != null ? Timestamp.fromDate(premiumRenewalDate!) : null,
      'premiumPlanType': premiumPlanType,
      'useBiometrics': useBiometrics,
      'hapticPatternType': hapticPatternType,
      'mapLineColor': mapLineColor,
      'mapLineStyle': mapLineStyle,
      'stats': stats,
      'u1InSanctuary': u1InSanctuary,
      'u2InSanctuary': u2InSanctuary,
      'u1SanctuaryLastSeen': u1SanctuaryLastSeen != null ? Timestamp.fromDate(u1SanctuaryLastSeen!) : null,
      'u2SanctuaryLastSeen': u2SanctuaryLastSeen != null ? Timestamp.fromDate(u2SanctuaryLastSeen!) : null,
      'customChatBackgroundUrl': customChatBackgroundUrl,
      'status': status,
    };
  }

  String toJson() => json.encode(toFirestoreMap());
  Map<String, dynamic> toFirestoreMap() {
    final map = toFirestore();
    map.forEach((key, value) {
      if (value is Timestamp) {
        map[key] = value.toDate().toIso8601String();
      // ignore: curly_braces_in_flow_control_structures
      } else if (value is DateTime) map[key] = value.toIso8601String();
    });
    return map;
  }

  factory RelationshipModel.fromFirestoreMap(Map<String, dynamic> map, {String? id}) {
    final processed = Map<String, dynamic>.from(map);
    processed.forEach((key, value) {
      if (value is String && value.contains('-') && value.contains('T')) {
        try { processed[key] = Timestamp.fromDate(DateTime.parse(value)); } catch (_) {}
      }
    });
    return RelationshipModel.fromFirestore(processed, id: id);
  }

  static RelationshipModel fromJson(String source) => RelationshipModel.fromFirestoreMap(json.decode(source));

  RelationshipModel copyWith({
    String? id,
    String? uid1,
    String? uid2,
    List<String>? uids,
    String? inviteCode,
    DateTime? createdAt,
    String? userName1,
    String? userName2,
    String? userLocation1,
    String? userLocation2,
    String? userMood1,
    String? userMood2,
    String? userPhoto1,
    String? userPhoto2,
    String? user1PartnerNickname,
    String? user2PartnerNickname,
    String? partnerFcmToken,
    String? lastTouchType,
    String? lastTouchFrom,
    DateTime? lastTouchTime,
    Map<String, String>? userTokens,
    DateTime? anniversaryDate,
    DateTime? nextMeetingDate,
    DateTime? lastMeetingDate,
    double? distanceKm,
    String? loveQuote,
    String? tripDestination,
    DateTime? tripDate,
    DateTime? tripEndDate,
    double? tripBudget,
    String? tripNotes,
    String? tripAccommodation,
    String? tripTransport,
    String? tripMustSee,
    String? tripMood,
    String? tripStory,
    Map<String, bool>? tripExcitement,
    String? privateSpacePin,
    String? privateSpaceTimeout,
    int? privateSpaceStorageBytes,
    DateTime? user1LastActive,
    DateTime? user2LastActive,
    int? streakCount,
    int? streakShields,
    DateTime? lastStreakIncrement,
    bool? isPlus,
    DateTime? user1SyncPress,
    DateTime? user2SyncPress,
    double? user1Lat,
    double? user1Lng,
    double? user2Lat,
    double? user2Lng,
    int? user1TimezoneOffset,
    int? user2TimezoneOffset,
    int? user1Battery,
    int? user2Battery,
    bool? user1IsCharging,
    bool? user2IsCharging,
    String? pinResetRequestBy,
    DateTime? pinResetRequestAt,
    bool? pinResetApproved,
    DateTime? pinResetOtpExpiry,
    String? pinResetOtp1,
    String? pinResetOtp2,
    int? chatBackgroundIndex,
    String? premiumTransactionId,
    DateTime? premiumRenewalDate,
    String? premiumPlanType,
    bool? useBiometrics,
    String? hapticPatternType,
    String? mapLineColor,
    String? mapLineStyle,
    Map<String, int>? stats,
    bool? u1InSanctuary,
    bool? u2InSanctuary,
    DateTime? u1SanctuaryLastSeen,
    DateTime? u2SanctuaryLastSeen,
    String? customChatBackgroundUrl,
    String? status,
  }) {
    return RelationshipModel(
      id: id ?? this.id,
      uid1: uid1 ?? this.uid1,
      uid2: uid2 ?? this.uid2,
      uids: uids ?? this.uids,
      inviteCode: inviteCode ?? this.inviteCode,
      createdAt: createdAt ?? this.createdAt,
      userName1: userName1 ?? this.userName1,
      userName2: userName2 ?? this.userName2,
      userLocation1: userLocation1 ?? this.userLocation1,
      userLocation2: userLocation2 ?? this.userLocation2,
      userMood1: userMood1 ?? this.userMood1,
      userMood2: userMood2 ?? this.userMood2,
      userPhoto1: userPhoto1 ?? this.userPhoto1,
      userPhoto2: userPhoto2 ?? this.userPhoto2,
      user1PartnerNickname: user1PartnerNickname ?? this.user1PartnerNickname,
      user2PartnerNickname: user2PartnerNickname ?? this.user2PartnerNickname,
      partnerFcmToken: partnerFcmToken ?? this.partnerFcmToken,
      lastTouchType: lastTouchType ?? this.lastTouchType,
      lastTouchFrom: lastTouchFrom ?? this.lastTouchFrom,
      lastTouchTime: lastTouchTime ?? this.lastTouchTime,
      userTokens: userTokens ?? this.userTokens,
      anniversaryDate: anniversaryDate ?? this.anniversaryDate,
      nextMeetingDate: nextMeetingDate ?? this.nextMeetingDate,
      lastMeetingDate: lastMeetingDate ?? this.lastMeetingDate,
      distanceKm: distanceKm ?? this.distanceKm,
      loveQuote: loveQuote ?? this.loveQuote,
      tripDestination: tripDestination ?? this.tripDestination,
      tripDate: tripDate ?? this.tripDate,
      tripEndDate: tripEndDate ?? this.tripEndDate,
      tripBudget: tripBudget ?? this.tripBudget,
      tripNotes: tripNotes ?? this.tripNotes,
      tripAccommodation: tripAccommodation ?? this.tripAccommodation,
      tripTransport: tripTransport ?? this.tripTransport,
      tripMustSee: tripMustSee ?? this.tripMustSee,
      tripMood: tripMood ?? this.tripMood,
      tripStory: tripStory ?? this.tripStory,
      tripExcitement: tripExcitement ?? this.tripExcitement,
      privateSpacePin: privateSpacePin ?? this.privateSpacePin,
      privateSpaceTimeout: privateSpaceTimeout ?? this.privateSpaceTimeout,
      privateSpaceStorageBytes: privateSpaceStorageBytes ?? this.privateSpaceStorageBytes,
      user1LastActive: user1LastActive ?? this.user1LastActive,
      user2LastActive: user2LastActive ?? this.user2LastActive,
      streakCount: streakCount ?? this.streakCount,
      streakShields: streakShields ?? this.streakShields,
      lastStreakIncrement: lastStreakIncrement ?? this.lastStreakIncrement,
      isPlus: isPlus ?? this.isPlus,
      user1SyncPress: user1SyncPress ?? this.user1SyncPress,
      user2SyncPress: user2SyncPress ?? this.user2SyncPress,
      user1Lat: user1Lat ?? this.user1Lat,
      user1Lng: user1Lng ?? this.user1Lng,
      user2Lat: user2Lat ?? this.user2Lat,
      user2Lng: user2Lng ?? this.user2Lng,
      user1TimezoneOffset: user1TimezoneOffset ?? this.user1TimezoneOffset,
      user2TimezoneOffset: user2TimezoneOffset ?? this.user2TimezoneOffset,
      user1Battery: user1Battery ?? this.user1Battery,
      user2Battery: user2Battery ?? this.user2Battery,
      user1IsCharging: user1IsCharging ?? this.user1IsCharging,
      user2IsCharging: user2IsCharging ?? this.user2IsCharging,
      pinResetRequestBy: pinResetRequestBy ?? this.pinResetRequestBy,
      pinResetRequestAt: pinResetRequestAt ?? this.pinResetRequestAt,
      pinResetApproved: pinResetApproved ?? this.pinResetApproved,
      pinResetOtpExpiry: pinResetOtpExpiry ?? this.pinResetOtpExpiry,
      pinResetOtp1: pinResetOtp1 ?? this.pinResetOtp1,
      pinResetOtp2: pinResetOtp2 ?? this.pinResetOtp2,
      chatBackgroundIndex: chatBackgroundIndex ?? this.chatBackgroundIndex,
      premiumTransactionId: premiumTransactionId ?? this.premiumTransactionId,
      premiumRenewalDate: premiumRenewalDate ?? this.premiumRenewalDate,
      premiumPlanType: premiumPlanType ?? this.premiumPlanType,
      useBiometrics: useBiometrics ?? this.useBiometrics,
      hapticPatternType: hapticPatternType ?? this.hapticPatternType,
      mapLineColor: mapLineColor ?? this.mapLineColor,
      mapLineStyle: mapLineStyle ?? this.mapLineStyle,
      stats: stats ?? this.stats,
      u1InSanctuary: u1InSanctuary ?? this.u1InSanctuary,
      u2InSanctuary: u2InSanctuary ?? this.u2InSanctuary,
      u1SanctuaryLastSeen: u1SanctuaryLastSeen ?? this.u1SanctuaryLastSeen,
      u2SanctuaryLastSeen: u2SanctuaryLastSeen ?? this.u2SanctuaryLastSeen,
      customChatBackgroundUrl: customChatBackgroundUrl ?? this.customChatBackgroundUrl,
      status: status ?? this.status,
    );
  }
}
