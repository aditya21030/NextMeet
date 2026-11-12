import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:home_widget/home_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants.dart';
import '../models/relationship_model.dart';
import 'cloud_relationship_service.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../widgets/couple_widgets/couple_widgets.dart';

class WidgetService {
  static const String _androidWidgetName = 'OurPulseWidgetProvider';
  static const String _qualifiedAndroidWidgetName = 'com.yousful.nextmeet.OurPulseWidgetProvider';

  /// Format exact calendar years/months/days together without negative or 12m wrap-around.
  static String formatTogetherBreakdown(DateTime anniversaryDate, [DateTime? referenceNow]) {
    final now = referenceNow ?? DateTime.now();
    if (now.isBefore(anniversaryDate)) return '0y 0m 0d';
    int years = now.year - anniversaryDate.year;
    int months = now.month - anniversaryDate.month;
    int days = now.day - anniversaryDate.day;
    if (days < 0) {
      months -= 1;
      days += DateTime(now.year, now.month, 0).day;
    }
    if (months < 0) {
      years -= 1;
      months += 12;
    }
    return '${years}y ${months}m ${days}d';
  }

  /// Calculate the next upcoming day milestone above [daysTogether].
  static ({int nextTarget, int daysLeft, double progress}) computeMilestoneProgress(int daysTogether) {
    final safeDays = daysTogether.clamp(0, 999999);
    const milestoneTargets = [50, 100, 200, 365, 500, 730, 1000, 1500, 2000];
    int nextTarget = milestoneTargets.firstWhere(
      (t) => t > safeDays,
      orElse: () => ((safeDays ~/ 500) + 1) * 500,
    );
    final daysLeft = (nextTarget - safeDays).clamp(1, 5000);
    final progress = (safeDays / nextTarget).clamp(0.05, 0.99);
    return (nextTarget: nextTarget, daysLeft: daysLeft, progress: progress);
  }

  /// Format human-readable relative string for last physical meeting.
  static String formatLastMetAgo(DateTime lastMeetingDate, [DateTime? referenceNow]) {
    final now = referenceNow ?? DateTime.now();
    final diffDays = now.difference(lastMeetingDate).inDays.abs();
    if (diffDays == 0) return 'Last met today';
    if (diffDays < 30) return 'Last met ${diffDays}d ago';
    if (diffDays < 365) return 'Last met ${diffDays ~/ 30} mo ago';
    return 'Last met ${diffDays ~/ 365}y ago';
  }

  /// Derive a 3-letter code from a city name cleanly.
  static String formatAirportCode(String city, {String fallback = 'YOU'}) {
    final cleaned = city.trim();
    if (cleaned.isEmpty) return fallback;
    if (cleaned.length >= 3) return cleaned.substring(0, 3).toUpperCase();
    return cleaned.toUpperCase();
  }

  /// Format UTC offset minutes (e.g., 330 -> "UTC+5:30").
  static String formatTimezoneLabel(int offsetMinutes) {
    final absMin = offsetMinutes.abs();
    final h = absMin ~/ 60;
    final m = absMin % 60;
    final sign = offsetMinutes >= 0 ? '+' : '-';
    return m == 0 ? 'UTC$sign$h' : 'UTC$sign$h:${m.toString().padLeft(2, '0')}';
  }

  static Future<void> updateWidgetData(
    RelationshipModel rel,
    String currentUid, {
    String? activeWidgetId,
    WidgetPalette? palette,
  }) async {
    try {
      final now = DateTime.now();
      final partnerName = rel.getDisplayPartnerName(currentUid);
      final myName = rel.getMyName(currentUid);
      final partnerMood = rel.getPartnerMood(currentUid);

      // Calculate Milestones & Together Time
      final daysTogether = now.difference(rel.anniversaryDate).inDays.clamp(0, 999999);
      final togetherBreakdown = formatTogetherBreakdown(rel.anniversaryDate, now);

      // Next Milestone
      final milestone = computeMilestoneProgress(daysTogether);
      final nextTarget = milestone.nextTarget;
      final daysToMilestone = milestone.daysLeft;

      final nextMeetDiff = rel.nextMeetingDate.difference(now);

      final bool isToday = now.year == rel.nextMeetingDate.year &&
          now.month == rel.nextMeetingDate.month &&
          now.day == rel.nextMeetingDate.day;
      final bool isPast = !isToday && rel.nextMeetingDate.isBefore(now);
      final DateTime tomorrowDate = now.add(const Duration(days: 1));
      final bool isTomorrow = tomorrowDate.year == rel.nextMeetingDate.year &&
          tomorrowDate.month == rel.nextMeetingDate.month &&
          tomorrowDate.day == rel.nextMeetingDate.day;

      String countdownVal = "Soon ❤️";
      String countdownSub = "NEXT REUNION";
      String reunionDate = DateFormat('MMM d, yyyy').format(rel.nextMeetingDate).toUpperCase();

      if (isToday) {
        countdownVal = "TODAY! 🎉";
        countdownSub = "REUNION DAY ❤️";
      } else if (isPast) {
        countdownVal = "PLAN VISIT ✈️";
        countdownSub = "TAP TO SET REUNION";
        reunionDate = "DATE PASSED";
      } else if (nextMeetDiff.inDays > 0) {
        countdownVal = "${nextMeetDiff.inDays} DAYS";
        countdownSub = "${nextMeetDiff.inHours % 24}H REMAINING";
      } else if (nextMeetDiff.inHours > 0) {
        countdownVal = "${nextMeetDiff.inHours} HOURS";
        countdownSub = "${nextMeetDiff.inMinutes % 60}M REMAINING";
      } else {
        countdownVal = "${nextMeetDiff.inMinutes} MINS";
        countdownSub = "ALMOST THERE!";
      }

      // Battery, Online & Sleep Status
      final partnerBatteryLevel = rel.getPartnerBattery(currentUid);
      final partnerBatteryStr = partnerBatteryLevel != null ? "$partnerBatteryLevel%" : "--%";
      final isCharging = rel.isPartnerCharging(currentUid);
      final isLowBattery = partnerBatteryLevel != null && partnerBatteryLevel < 20;
      final partnerLastActive = rel.getPartnerLastActive(currentUid);
      final bool isPartnerOnline = partnerLastActive != null &&
          now.difference(partnerLastActive).inMinutes.abs() < 10;

      // Partner Local Time & Timezone Offset
      final partnerOffsetMinutes = rel.getPartnerTimezoneOffset(currentUid);
      final partnerTime = now.toUtc().add(Duration(minutes: partnerOffsetMinutes));
      final partnerTimeStr = DateFormat('h:mm a').format(partnerTime);
      final myTimeStr = DateFormat('h:mm a').format(now);
      final bool isPartnerAsleep = partnerTime.hour >= 23 || partnerTime.hour < 7;
      final partnerTzLabel = formatTimezoneLabel(partnerOffsetMinutes);

      // Clean City Names (strip commas and country codes)
      String origin = rel.getMyLocation(currentUid).split(',').first.trim();
      if (origin.isEmpty) origin = "You";
      String dest = rel.getPartnerLocation(currentUid).split(',').first.trim();
      if (dest.isEmpty) dest = partnerName;

      // Distance
      final dist = (rel.computedDistance > 0) ? rel.computedDistance : rel.distanceKm;
      final distStr = dist > 0 ? '${NumberFormat("#,###").format(dist.round())} km' : "1,506 km";

      // Save Data to HomeWidget
      await HomeWidget.saveWidgetData<String>('relId', rel.id ?? '');
      await HomeWidget.saveWidgetData<String>('myUid', currentUid);
      await HomeWidget.saveWidgetData<String>('partnerName', partnerName);
      await HomeWidget.saveWidgetData<String>('partnerMood', partnerMood);
      await HomeWidget.saveWidgetData<String>('distance', distStr);
      await HomeWidget.saveWidgetData<String>('daysTogether', "$daysTogether Days");
      await HomeWidget.saveWidgetData<String>('togetherBreakdown', togetherBreakdown);
      await HomeWidget.saveWidgetData<String>('nextMeet', countdownVal);
      await HomeWidget.saveWidgetData<String>('lastSeen', "Synced: ${DateFormat('HH:mm').format(now)}");

      // Boarding Pass & Battery fields
      await HomeWidget.saveWidgetData<String>('partnerBattery', partnerBatteryStr);
      await HomeWidget.saveWidgetData<bool>('isPartnerCharging', isCharging);
      await HomeWidget.saveWidgetData<bool>('isLowBattery', isLowBattery);
      await HomeWidget.saveWidgetData<bool>('isPartnerAsleep', isPartnerAsleep);
      await HomeWidget.saveWidgetData<String>('originCity', origin);
      await HomeWidget.saveWidgetData<String>('destCity', dest);
      await HomeWidget.saveWidgetData<String>('countdownVal', countdownVal);
      await HomeWidget.saveWidgetData<String>('countdownSub', countdownSub);
      await HomeWidget.saveWidgetData<String>('reunionDate', reunionDate);

      // Clocks & Milestones
      await HomeWidget.saveWidgetData<String>('myLocalTime', myTimeStr);
      await HomeWidget.saveWidgetData<String>('partnerLocalTime', partnerTimeStr);
      await HomeWidget.saveWidgetData<bool>('isPartnerOnline', isPartnerOnline);
      await HomeWidget.saveWidgetData<int>('nextMilestoneDays', daysToMilestone);
      await HomeWidget.saveWidgetData<String>('nextMilestoneTarget', "$nextTarget days");
      await HomeWidget.saveWidgetData<int>('streakDays', rel.streakCount);

      // Retrieve or save active widget ID & Palette
      final savedWidgetId = activeWidgetId ??
          (await HomeWidget.getWidgetData<String>('active_widget_id')) ??
          'distance_battery';
      await HomeWidget.saveWidgetData<String>('active_widget_id', savedWidgetId);

      WidgetPalette effectivePalette;
      if (palette != null) {
        effectivePalette = palette;
        await HomeWidget.saveWidgetData<String>('widget_palette', palette.name);
      } else {
        final storedPaletteName = await HomeWidget.getWidgetData<String>('widget_palette');
        effectivePalette = WidgetPalette.values.firstWhere(
          (p) => p.name == storedPaletteName,
          orElse: () => WidgetPalette.pink,
        );
      }

      // Render Flutter Widget to PNG image for Android Home Screen Widget
      try {
        final activeWidget = _buildActiveWidgetForRendering(
          widgetId: savedWidgetId,
          rel: rel,
          currentUid: currentUid,
          distStr: distStr,
          origin: origin,
          dest: dest,
          partnerName: partnerName,
          myName: myName,
          battery: partnerBatteryLevel ?? 87,
          myTimeStr: myTimeStr,
          partnerTimeStr: partnerTimeStr,
          partnerTzLabel: partnerTzLabel,
          daysTogether: daysTogether,
          togetherBreakdown: togetherBreakdown,
          countdownVal: countdownVal,
          countdownSub: countdownSub,
          isToday: isToday,
          isTomorrow: isTomorrow,
          isPartnerOnline: isPartnerOnline,
          isLowBattery: isLowBattery,
          isPartnerAsleep: isPartnerAsleep,
          palette: effectivePalette,
        );

        final logicalSize = _getWidgetLogicalSize(savedWidgetId);

        // Pixel budget stays under ~440KB ARGB8888 so Android Binder IPC never drops the Bitmap
        final safePixelRatio = math
            .sqrt(110000.0 / (logicalSize.width * logicalSize.height))
            .clamp(0.88, 1.5);

        await HomeWidget.renderFlutterWidget(
          MediaQuery(
            data: MediaQueryData(size: logicalSize),
            child: Material(
              type: MaterialType.transparency,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: activeWidget,
              ),
            ),
          ),
          key: 'active_widget_img',
          logicalSize: logicalSize,
          pixelRatio: safePixelRatio,
        );
      } catch (e) {
        // ignore: avoid_print
        print('Widget Image Render Error: $e');
      }

      await HomeWidget.updateWidget(
        name: _androidWidgetName,
        androidName: _androidWidgetName,
        qualifiedAndroidName: _qualifiedAndroidWidgetName,
      );
    } catch (e) {
      // ignore: avoid_print
      print('Widget Update Error: $e');
    }
  }

  static Widget _buildActiveWidgetForRendering({
    required String widgetId,
    required RelationshipModel rel,
    required String currentUid,
    required String distStr,
    required String origin,
    required String dest,
    required String partnerName,
    required String myName,
    required int battery,
    required String myTimeStr,
    required String partnerTimeStr,
    required String partnerTzLabel,
    required int daysTogether,
    required String togetherBreakdown,
    required String countdownVal,
    required String countdownSub,
    required bool isToday,
    required bool isTomorrow,
    required bool isPartnerOnline,
    required bool isLowBattery,
    required bool isPartnerAsleep,
    required WidgetPalette palette,
  }) {
    final now = DateTime.now();
    final isPartnerHolding = (() {
      final partnerSync = currentUid == rel.uid1 ? rel.user2SyncPress : rel.user1SyncPress;
      return partnerSync != null && now.difference(partnerSync).inSeconds.abs() < 12;
    })();

    switch (widgetId) {
      case 'couple_dashboard':
        return CoupleDashboardWidget(
          partnerName: partnerName,
          battery: battery,
          streak: rel.streakCount,
          isOnline: isPartnerOnline,
          isPartnerHolding: isPartnerHolding,
          myTime: myTimeStr,
          partnerTime: partnerTimeStr,
          distance: distStr,
          meetupCountdown: countdownVal,
          meetupDate: DateFormat('EEE d MMM').format(rel.nextMeetingDate),
          togetherDuration: 'Together $togetherBreakdown',
          lastMet: formatLastMetAgo(rel.lastMeetingDate, now),
        );

      case 'heartbeat_sync':
        final recentTouch = rel.lastTouchTime != null &&
            now.difference(rel.lastTouchTime!).inMinutes.abs() < 2 &&
            rel.lastTouchFrom != currentUid;
        final hbState = (isPartnerHolding || recentTouch)
            ? HeartbeatWidgetState.touching
            : (isPartnerOnline ? HeartbeatWidgetState.idle : HeartbeatWidgetState.offline);
        return HeartbeatSyncWidget(
          partnerName: partnerName,
          bpm: 74,
          state: hbState,
        );

      case 'reunion_countdown':
        final cdState = isToday
            ? CountdownWidgetState.today
            : (isTomorrow ? CountdownWidgetState.tomorrow : CountdownWidgetState.daysHours);
        final totalDays = math.max(1, rel.nextMeetingDate.difference(rel.lastMeetingDate).inDays);
        final remainingDays = rel.nextMeetingDate.difference(now).inDays.clamp(0, totalDays);
        final cdProgress = (1.0 - (remainingDays / totalDays)).clamp(0.08, 1.0);
        return ReunionCountdownWidget(
          state: cdState,
          palette: palette,
          partnerName: partnerName,
          countdownText: countdownVal,
          subText: '${DateFormat('EEE d MMM').format(rel.nextMeetingDate)}, $origin to $dest',
          originAirport: formatAirportCode(origin, fallback: 'YOU'),
          destAirport: formatAirportCode(dest, fallback: 'PRT'),
          progress: cdProgress,
        );

      case 'daily_moments':
        return DailyMomentsPhotoWidget(
          state: MomentsWidgetState.partnerMoment,
          partnerName: partnerName,
          timeText: 'Today, $partnerTimeStr',
          caption: rel.loveQuote.isNotEmpty
              ? rel.loveQuote
              : 'Thinking of you always ❤️',
        );

      case 'together_counter':
        return TogetherCounterWidget(
          days: daysTogether,
          breakdown: togetherBreakdown,
        );

      case 'quick_touch':
        return QuickTouchWidget(
          partnerName: partnerName,
        );

      case 'two_clocks':
        return TwoClocksWidget(
          myName: myName,
          myTime: myTimeStr,
          partnerName: partnerName,
          partnerTime: partnerTimeStr,
          distance: distStr,
        );

      case 'next_milestone':
        final milestone = computeMilestoneProgress(daysTogether);
        return NextMilestoneWidget(
          daysLeft: milestone.daysLeft,
          targetMilestone: '${milestone.nextTarget} days',
          progress: milestone.progress,
        );

      case 'game_status':
        return GameStatusWidget(
          partnerName: partnerName,
          state: GameWidgetState.yourMove,
        );

      case 'love_note':
        return LoveNoteWidget(
          partnerName: partnerName,
          noteSnippet: rel.loveQuote.isNotEmpty
              ? rel.loveQuote
              : 'Thinking of you, always.',
          timeAgo: 'Updated ${DateFormat('h:mm a').format(now)}',
          state: LoveNoteWidgetState.normal,
        );

      case 'trip_tracker':
        final tripCity = (rel.tripDestination != null && rel.tripDestination!.trim().isNotEmpty)
            ? rel.tripDestination!.trim()
            : dest;
        final tripState = rel.tripDate == null
            ? TripWidgetState.scheduled
            : (rel.tripDate!.isBefore(now) ? TripWidgetState.landed : TripWidgetState.scheduled);
        return TripTrackerWidget(
          state: tripState,
          partnerName: partnerName,
          flightNumber: (rel.tripTransport != null && rel.tripTransport!.trim().isNotEmpty)
              ? rel.tripTransport!.trim()
              : 'Upcoming Trip',
          originCode: formatAirportCode(origin, fallback: 'YOU'),
          originCity: origin,
          destCode: formatAirportCode(tripCity, fallback: 'DST'),
          destCity: tripCity,
          timeText: rel.tripDate != null ? DateFormat('MMM d').format(rel.tripDate!) : partnerTimeStr,
        );

      case 'next_event':
        final tripName = (rel.tripDestination != null && rel.tripDestination!.trim().isNotEmpty)
            ? 'Trip to ${rel.tripDestination!.trim()}'
            : 'Watch Together';
        final tripWhen = rel.tripDate != null
            ? DateFormat('EEE, d MMM').format(rel.tripDate!)
            : 'Next Shared Plan';
        return NextEventWidget(
          event1Title: 'Next Reunion',
          event1Sub: DateFormat('EEE, d MMM').format(rel.nextMeetingDate),
          event1Time: countdownVal,
          event2Title: tripName,
          event2Sub: tripWhen,
          event2Time: rel.tripDate != null ? DateFormat('h:mm a').format(rel.tripDate!) : 'Soon',
        );

      case 'memory_of_the_day':
        return MemoryOfTheDayWidget(
          dateTitle: 'OUR JOURNEY STARTED',
          memoryTitle: 'Sweet Memory with $partnerName',
          memoryDate: DateFormat('d MMM yyyy').format(rel.anniversaryDate),
        );

      case 'distance_battery':
      default:
        return DistanceBatteryWidget(
          distance: distStr,
          fromCity: origin,
          toCity: dest,
          partnerName: partnerName,
          battery: battery,
          timeText: '$partnerTzLabel, $partnerTimeStr',
          state: isLowBattery
              ? DistanceBatteryState.lowBattery
              : (isPartnerAsleep ? DistanceBatteryState.asleep : DistanceBatteryState.normal),
        );
    }
  }

  static Size _getWidgetLogicalSize(String widgetId) {
    switch (widgetId) {
      case 'heartbeat_sync':
      case 'together_counter':
      case 'quick_touch':
      case 'next_milestone':
      case 'game_status':
        return const Size(174, 174);
      case 'two_clocks':
        return const Size(358, 84);
      case 'daily_moments':
      case 'memory_of_the_day':
      case 'couple_dashboard':
        return const Size(358, 358);
      case 'distance_battery':
      case 'reunion_countdown':
      case 'love_note':
      case 'trip_tracker':
      case 'next_event':
      default:
        return const Size(358, 174);
    }
  }
}

/// Headless background callback for interactive widget touches (miss, hug, touch, sync, cheer)
@pragma('vm:entry-point')
Future<void> homeWidgetBackgroundCallback(Uri? uri) async {
  if (uri == null) return;
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {}

  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  } catch (_) {}

  final type = uri.queryParameters['type'] ?? 'touch';
  final relId = await HomeWidget.getWidgetData<String>('relId');
  final partnerName = (await HomeWidget.getWidgetData<String>('partnerName')) ?? 'Partner';

  if (relId != null && relId.isNotEmpty) {
    try {
      final cloudService = CloudRelationshipService();
      await cloudService.sendTouch(relId, type).timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  String feedback = 'Sent Love to $partnerName! ❤️';
  if (type == 'miss') feedback = 'Sent Miss You to $partnerName! ❤️';
  if (type == 'hug') feedback = 'Sent Warm Hug to $partnerName! 🤗';
  if (type == 'touch') feedback = 'Sent Touch to $partnerName! ⚡';
  if (type == 'cheer') feedback = 'Sent Cheer & Sparkle to $partnerName! ⭐';
  if (type == 'sync' || type == 'heartbeat') feedback = 'Heartbeat Synced! 💓';

  await HomeWidget.saveWidgetData<String>('lastFeedback', feedback);
  await HomeWidget.saveWidgetData<int>('lastFeedbackTime', DateTime.now().millisecondsSinceEpoch);
  await HomeWidget.updateWidget(
    name: WidgetService._androidWidgetName,
    androidName: WidgetService._androidWidgetName,
    qualifiedAndroidName: WidgetService._qualifiedAndroidWidgetName,
  );
}
