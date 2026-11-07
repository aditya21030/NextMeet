import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nextmeet/widgets/couple_widgets/couple_widgets.dart';

void main() {
  testWidgets('All 14 NextMeet Couple Widgets Smoke Test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                DistanceBatteryWidget(),
                HeartbeatSyncWidget(),
                ReunionCountdownWidget(),
                DailyMomentsPhotoWidget(),
                TogetherCounterWidget(),
                QuickTouchWidget(),
                TwoClocksWidget(),
                NextMilestoneWidget(),
                GameStatusWidget(),
                LoveNoteWidget(),
                TripTrackerWidget(),
                NextEventWidget(),
                MemoryOfTheDayWidget(),
                CoupleDashboardWidget(),
              ],
            ),
          ),
        ),
      ),
    );

    // Verify all 14 widgets are rendered
    expect(find.byType(DistanceBatteryWidget), findsOneWidget);
    expect(find.byType(HeartbeatSyncWidget), findsOneWidget);
    expect(find.byType(ReunionCountdownWidget), findsOneWidget);
    expect(find.byType(DailyMomentsPhotoWidget), findsOneWidget);
    expect(find.byType(TogetherCounterWidget), findsOneWidget);
    expect(find.byType(QuickTouchWidget), findsOneWidget);
    expect(find.byType(TwoClocksWidget), findsOneWidget);
    expect(find.byType(NextMilestoneWidget), findsOneWidget);
    expect(find.byType(GameStatusWidget), findsOneWidget);
    expect(find.byType(LoveNoteWidget), findsOneWidget);
    expect(find.byType(TripTrackerWidget), findsOneWidget);
    expect(find.byType(NextEventWidget), findsOneWidget);
    expect(find.byType(MemoryOfTheDayWidget), findsOneWidget);
    expect(find.byType(CoupleDashboardWidget), findsOneWidget);
  });

  testWidgets('Quick Touch interactive callback test', (WidgetTester tester) async {
    String? triggeredAction;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickTouchWidget(
            onAction: (act) {
              triggeredAction = act;
            },
          ),
        ),
      ),
    );

    expect(find.text('Miss you'), findsOneWidget);
    await tester.tap(find.text('Miss you'));
    expect(triggeredAction, equals('miss_you'));

    await tester.tap(find.text('Hug'));
    expect(triggeredAction, equals('hug'));
  });
}
