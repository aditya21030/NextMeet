import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import '../models/relationship_model.dart';
import 'package:intl/intl.dart';

class WidgetService {
  static const String _androidWidgetName = 'com.yousful.nextmeet.OurPulseWidgetProvider';

  static Future<void> updateWidgetData(RelationshipModel rel, String currentUid) async {
    try {
      final now = DateTime.now();
      // Robust Name Logic: Prioritize Pet Names
      final partnerName = rel.getDisplayPartnerName(currentUid);
      final partnerMood = rel.getPartnerMood(currentUid);
      
      // Calculate Milestones with actual fallbacks
      final daysTogether = now.difference(rel.anniversaryDate).inDays;
      final nextMeetDiff = rel.nextMeetingDate.difference(now);
      
      String nextMeetText = "Soon ❤️";
      if (nextMeetDiff.isNegative) {
        nextMeetText = "Today ✨";
      } else if (nextMeetDiff.inDays > 0) {
        nextMeetText = "${nextMeetDiff.inDays} Days Left";
      } else if (nextMeetDiff.inHours > 0) {
        nextMeetText = "${nextMeetDiff.inHours} Hours Left";
      }

      await HomeWidget.saveWidgetData<String>('partnerName', partnerName);
      await HomeWidget.saveWidgetData<String>('partnerMood', partnerMood);
      await HomeWidget.saveWidgetData<String>('distance', rel.widgetDistance);
      await HomeWidget.saveWidgetData<String>('daysTogether', "$daysTogether Days");
      await HomeWidget.saveWidgetData<String>('nextMeet', nextMeetText);
      await HomeWidget.saveWidgetData<String>('lastSeen', "Updated: ${DateFormat('HH:mm').format(now)}");

      await HomeWidget.updateWidget(
        androidName: _androidWidgetName,
      );
    } catch (e) {
      print('Widget Update Error: $e');
    }
  }
}
