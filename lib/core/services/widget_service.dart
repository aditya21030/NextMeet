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
      
      // Calculate Milestones
      final daysTogether = now.difference(rel.anniversaryDate).inDays;
      final nextMeetDiff = rel.nextMeetingDate.difference(now);
      
      String countdownVal = "Soon ❤️";
      String countdownSub = "NEXT REUNION";
      if (nextMeetDiff.isNegative) {
        countdownVal = "TODAY ✨";
        countdownSub = "TOGETHER AGAIN";
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

      // Battery status
      final partnerBatteryLevel = rel.getPartnerBattery(currentUid);
      final partnerBatteryStr = partnerBatteryLevel != null ? "$partnerBatteryLevel%" : "--%";
      final isCharging = rel.isPartnerCharging(currentUid);

      // Cities & Route
      String origin = rel.getMyLocation(currentUid).trim();
      if (origin.isEmpty) origin = "YOU";
      String dest = rel.getPartnerLocation(currentUid).trim();
      if (dest.isEmpty) dest = partnerName;

      // Distance
      final distStr = rel.computedDistance <= 0 ? "0 KM" : "${rel.computedDistance.toStringAsFixed(0)} KM";
      final reunionDate = DateFormat('MMM d, yyyy').format(rel.nextMeetingDate).toUpperCase();

      // Legacy fields
      await HomeWidget.saveWidgetData<String>('partnerName', partnerName);
      await HomeWidget.saveWidgetData<String>('partnerMood', partnerMood);
      await HomeWidget.saveWidgetData<String>('distance', distStr);
      await HomeWidget.saveWidgetData<String>('daysTogether', "$daysTogether Days");
      await HomeWidget.saveWidgetData<String>('nextMeet', countdownVal);
      await HomeWidget.saveWidgetData<String>('lastSeen', "Synced: ${DateFormat('HH:mm').format(now)}");

      // Boarding Pass & Battery fields
      await HomeWidget.saveWidgetData<String>('partnerBattery', partnerBatteryStr);
      await HomeWidget.saveWidgetData<bool>('isPartnerCharging', isCharging);
      await HomeWidget.saveWidgetData<String>('originCity', origin);
      await HomeWidget.saveWidgetData<String>('destCity', dest);
      await HomeWidget.saveWidgetData<String>('countdownVal', countdownVal);
      await HomeWidget.saveWidgetData<String>('countdownSub', countdownSub);
      await HomeWidget.saveWidgetData<String>('reunionDate', reunionDate);

      await HomeWidget.updateWidget(
        androidName: _androidWidgetName,
      );
    } catch (e) {
      // ignore: avoid_print
      print('Widget Update Error: $e');
    }
  }
}
