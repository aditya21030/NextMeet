import 'package:home_widget/home_widget.dart';
import '../models/relationship_model.dart';
import 'package:intl/intl.dart';

class WidgetService {
  static const String _androidWidgetName = 'com.yousful.nextmeet.OurPulseWidgetProvider';

  static Future<void> updateWidgetData(RelationshipModel rel, String currentUid) async {
    try {
      final now = DateTime.now();
      final partnerName = rel.getDisplayPartnerName(currentUid);
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
      if (origin.isEmpty) origin = "YOU";
      String dest = rel.getPartnerLocation(currentUid).split(',').first.trim();
      if (dest.isEmpty) dest = partnerName;

      // Distance
      final distStr = rel.computedDistance <= 0 ? "0 KM" : "${rel.computedDistance.toStringAsFixed(0)} KM";

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

      await HomeWidget.updateWidget(
        androidName: _androidWidgetName,
      );
    } catch (e) {
      // ignore: avoid_print
      print('Widget Update Error: $e');
    }
  }
}
