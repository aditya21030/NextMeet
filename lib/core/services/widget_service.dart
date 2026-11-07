import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import '../models/relationship_model.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../widgets/couple_widgets/couple_widgets.dart';

class WidgetService {
  static const String _androidWidgetName = 'OurPulseWidgetProvider';
  static const String _qualifiedAndroidWidgetName = 'com.yousful.nextmeet.OurPulseWidgetProvider';

  static Future<void> updateWidgetData(
    RelationshipModel rel,
    String currentUid, {
    String? activeWidgetId,
    WidgetPalette palette = WidgetPalette.pink,
  }) async {
    try {
      final now = DateTime.now();
      final partnerName = rel.getDisplayPartnerName(currentUid);
      final myName = rel.getMyName(currentUid);
      final partnerMood = rel.getPartnerMood(currentUid);

      // Calculate Milestones & Together Time
      final daysTogether = now.difference(rel.anniversaryDate).inDays;
      final years = daysTogether ~/ 365;
      final remainingDays = daysTogether % 365;
      final months = remainingDays ~/ 30;
      final days = remainingDays % 30;
      final togetherBreakdown = '${years}y ${months}m ${days}d';

      // Next Milestone
      final milestoneTargets = [50, 100, 200, 365, 500, 730, 1000, 1500, 2000];
      int nextTarget = 1000;
      for (final target in milestoneTargets) {
        if (target > daysTogether) {
          nextTarget = target;
          break;
        }
      }
      final daysToMilestone = (nextTarget - daysTogether).clamp(0, 1000);

      final nextMeetDiff = rel.nextMeetingDate.difference(now);

      final bool isToday = now.year == rel.nextMeetingDate.year &&
          now.month == rel.nextMeetingDate.month &&
          now.day == rel.nextMeetingDate.day;
      final bool isPast = !isToday && rel.nextMeetingDate.isBefore(now);

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

      // Battery & Sleep Status
      final partnerBatteryLevel = rel.getPartnerBattery(currentUid);
      final partnerBatteryStr = partnerBatteryLevel != null ? "$partnerBatteryLevel%" : "--%";
      final isCharging = rel.isPartnerCharging(currentUid);
      final isLowBattery = partnerBatteryLevel != null && partnerBatteryLevel < 20;

      // Partner Local Time & Timezone Offset
      final partnerOffsetMinutes = rel.getPartnerTimezoneOffset(currentUid);
      final partnerTime = now.toUtc().add(Duration(minutes: partnerOffsetMinutes));
      final partnerTimeStr = DateFormat('h:mm a').format(partnerTime);
      final myTimeStr = DateFormat('h:mm a').format(now);
      final isPartnerAsleep = partnerTime.hour >= 23 || partnerTime.hour < 7;

      // Clean City Names (strip commas and country codes)
      String origin = rel.getMyLocation(currentUid).split(',').first.trim();
      if (origin.isEmpty) origin = "You";
      String dest = rel.getPartnerLocation(currentUid).split(',').first.trim();
      if (dest.isEmpty) dest = partnerName;

      // Distance
      final dist = (rel.computedDistance > 0) ? rel.computedDistance : rel.distanceKm;
      final distStr = dist > 0 ? '${NumberFormat("#,###").format(dist.round())} km' : "1,506 km";

      // Save Data to HomeWidget
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
      await HomeWidget.saveWidgetData<int>('nextMilestoneDays', daysToMilestone);
      await HomeWidget.saveWidgetData<String>('nextMilestoneTarget', "$nextTarget days");
      await HomeWidget.saveWidgetData<int>('streakDays', rel.streakCount);

      // Retrieve or save active widget ID
      final savedWidgetId = activeWidgetId ??
          (await HomeWidget.getWidgetData<String>('active_widget_id')) ??
          'distance_battery';
      await HomeWidget.saveWidgetData<String>('active_widget_id', savedWidgetId);

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
          daysTogether: daysTogether,
          togetherBreakdown: togetherBreakdown,
          countdownVal: countdownVal,
          countdownSub: countdownSub,
          palette: palette,
        );

        final logicalSize = _getWidgetLogicalSize(savedWidgetId);

        // Safe pixel ratio ensuring rendered image is sharp yet stays comfortably within Android Binder 512KB IPC limit
        final maxDimension = logicalSize.width > logicalSize.height ? logicalSize.width : logicalSize.height;
        final safePixelRatio = (450.0 / maxDimension).clamp(1.0, 1.5);

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
    required int daysTogether,
    required String togetherBreakdown,
    required String countdownVal,
    required String countdownSub,
    required WidgetPalette palette,
  }) {
    switch (widgetId) {
      case 'couple_dashboard':
        return CoupleDashboardWidget(
          partnerName: partnerName,
          battery: battery,
          streak: rel.streakCount,
          myTime: myTimeStr,
          partnerTime: partnerTimeStr,
          distance: distStr,
          meetupCountdown: countdownVal,
          meetupDate: DateFormat('EEE d MMM').format(rel.nextMeetingDate),
          togetherDuration: 'Together $togetherBreakdown',
          lastMet: 'Last met ${rel.lastMeetingDate.difference(DateTime.now()).inDays.abs() ~/ 30} mo ago',
        );

      case 'heartbeat_sync':
        return HeartbeatSyncWidget(
          partnerName: partnerName,
          bpm: 74,
          state: HeartbeatWidgetState.touching,
        );

      case 'reunion_countdown':
        return ReunionCountdownWidget(
          state: CountdownWidgetState.daysHours,
          palette: palette,
          countdownText: countdownVal,
          subText: '$countdownSub, $origin to $dest',
          originAirport: origin.length >= 3 ? origin.substring(0, 3).toUpperCase() : 'YOU',
          destAirport: dest.length >= 3 ? dest.substring(0, 3).toUpperCase() : 'PARTNER',
          progress: 0.70,
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
        final milestoneTargets = [50, 100, 200, 365, 500, 730, 1000, 1500, 2000];
        int nextTarget = 1000;
        for (final target in milestoneTargets) {
          if (target > daysTogether) {
            nextTarget = target;
            break;
          }
        }
        final daysToMilestone = (nextTarget - daysTogether).clamp(0, 1000);
        return NextMilestoneWidget(
          daysLeft: daysToMilestone,
          targetMilestone: '$nextTarget days',
          progress: (daysTogether / nextTarget).clamp(0.05, 0.99),
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
          timeAgo: 'Just now',
          state: LoveNoteWidgetState.normal,
        );

      case 'trip_tracker':
        return TripTrackerWidget(
          state: TripWidgetState.inTheAir,
          flightNumber: 'Flight NM 204',
          originCode: origin.length >= 3 ? origin.substring(0, 3).toUpperCase() : 'YOU',
          originCity: origin,
          destCode: dest.length >= 3 ? dest.substring(0, 3).toUpperCase() : 'PARTNER',
          destCity: dest,
          timeText: partnerTimeStr,
        );

      case 'next_event':
        return NextEventWidget(
          event1Title: 'Next Reunion',
          event1Sub: DateFormat('EEE, d MMM').format(rel.nextMeetingDate),
          event1Time: countdownVal,
          event2Title: 'Watch Together',
          event2Sub: 'Movie Night Tonight',
          event2Time: '8:00 PM',
        );

      case 'memory_of_the_day':
        return MemoryOfTheDayWidget(
          dateTitle: 'ON THIS DAY',
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
          timeText: 'Local, $partnerTimeStr',
          state: battery < 20
              ? DistanceBatteryState.lowBattery
              : (DateTime.now().toUtc().add(Duration(minutes: rel.getPartnerTimezoneOffset(currentUid))).hour >= 23 ||
                      DateTime.now().toUtc().add(Duration(minutes: rel.getPartnerTimezoneOffset(currentUid))).hour < 7
                  ? DistanceBatteryState.asleep
                  : DistanceBatteryState.normal),
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
