import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nextmeet/core/services/widget_service.dart';
import 'package:nextmeet/widgets/couple_widgets/couple_widgets.dart';
import 'package:nextmeet/widgets/flat_components.dart';
import 'package:nextmeet/widgets/glass_card.dart';
import 'package:nextmeet/widgets/primary_button.dart';

void main() {
  testWidgets('All 14 NextMeet Couple Widgets Smoke & Edge-State Test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const DistanceBatteryWidget(state: DistanceBatteryState.lowBattery),
                  const HeartbeatSyncWidget(state: HeartbeatWidgetState.offline),
                  ...WidgetPalette.values.map(
                    (p) => ReunionCountdownWidget(
                      palette: p,
                      state: CountdownWidgetState.tomorrow,
                      partnerName: 'Ananya',
                    ),
                  ),
                  const DailyMomentsPhotoWidget(
                    state: MomentsWidgetState.waiting,
                    partnerName: 'Ananya',
                  ),
                  const DailyMomentsPhotoWidget(
                    state: MomentsWidgetState.sent,
                    partnerName: 'Ananya',
                    timeText: '8:15 PM',
                  ),
                  const TogetherCounterWidget(
                    days: 3650,
                    breakdown: '10y 0m 0d',
                  ),
                  const QuickTouchWidget(partnerName: 'Ananya'),
                  const TwoClocksWidget(
                    myName: 'You',
                    partnerName: 'Ananya',
                  ),
                  const NextMilestoneWidget(
                    daysLeft: 1250,
                    targetMilestone: '5000 days',
                    progress: 0.75,
                  ),
                  const GameStatusWidget(
                    partnerName: 'Ananya',
                    state: GameWidgetState.partnerTurn,
                  ),
                  const LoveNoteWidget(
                    partnerName: 'Ananya',
                    state: LoveNoteWidgetState.sealed,
                  ),
                  const TripTrackerWidget(
                    state: TripWidgetState.landed,
                    partnerName: 'Ananya',
                  ),
                  const NextEventWidget(),
                  const MemoryOfTheDayWidget(
                    memoryTitle: 'A Very Long Unforgettable Anniversary Trip Title',
                    memoryDate: '14 Feb 2025',
                  ),
                  const CoupleDashboardWidget(
                    partnerName: 'Ananya',
                    isOnline: false,
                    isPartnerHolding: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(DistanceBatteryWidget), findsOneWidget);
    expect(find.byType(HeartbeatSyncWidget), findsOneWidget);
    expect(find.byType(ReunionCountdownWidget), findsNWidgets(WidgetPalette.values.length));
    expect(find.byType(DailyMomentsPhotoWidget), findsNWidgets(2));
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

    // Dynamic partner name assertions (no hardcoded "Rahul" / "His" / "Sent 9:42 PM")
    expect(find.textContaining('Ananya flies'), findsNWidgets(WidgetPalette.values.length));
    expect(find.text("Ananya's moment will appear here"), findsOneWidget);
    expect(find.text('Sent 8:15 PM, seen by Ananya'), findsOneWidget);
    expect(find.text('Ananya is on the way'), findsOneWidget);
    expect(find.text('Away, battery 64%'), findsOneWidget);
    expect(find.text('Ananya is holding!'), findsOneWidget);

    // MemoryOfTheDayWidget polaroid artwork container must not collapse to 0px width
    final customPaints = find.descendant(
      of: find.byType(MemoryOfTheDayWidget),
      matching: find.byType(CustomPaint),
    );
    expect(customPaints, findsOneWidget);
    expect(tester.getSize(customPaints).width, greaterThan(200));
  });

  testWidgets('Quick Touch & Dashboard interactive callbacks test', (WidgetTester tester) async {
    String? triggeredAction;
    int heartSyncs = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              QuickTouchWidget(
                onAction: (act) => triggeredAction = act,
              ),
              CoupleDashboardWidget(
                onHeartHold: () => heartSyncs++,
                onQuickTouch: (act) => triggeredAction = act,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Miss you'), findsOneWidget);
    await tester.tap(find.text('Miss you'));
    expect(triggeredAction, equals('miss_you'));

    await tester.tap(find.text('Hug'));
    expect(triggeredAction, equals('hug'));

    await tester.tap(find.text('Hold to sync'));
    expect(heartSyncs, 0);
    await tester.longPress(find.byIcon(Icons.favorite_rounded).at(1));
    await tester.tap(find.byIcon(Icons.favorite_rounded).at(1));
    expect(heartSyncs, 2);
  });

  testWidgets('Shared UI components (GlassCard, PrimaryButton, TagChip, MascotHeart)', (WidgetTester tester) async {
    int cardTaps = 0;
    int btnTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 240,
          child: Column(
            children: [
              GlassCard(
                onTap: () => cardTaps++,
                child: const Text('Tap Glass'),
              ),
              PrimaryButton(
                text: 'Continue Journey',
                onPressed: () => btnTaps++,
              ),
              PrimaryButton(
                text: 'Syncing',
                isLoading: true,
                onPressed: () => btnTaps++,
              ),
              const SizedBox(
                width: 120,
                child: TagChip(
                  label: 'Super Long Couple Tag Label That Truncates Cleanly',
                  icon: Icons.favorite,
                ),
              ),
              const TwoMascotsRow(),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Tap Glass'));
    expect(cardTaps, 1);

    await tester.tap(find.text('Continue Journey'));
    expect(btnTaps, 1);

    // Loading button ignores taps
    await tester.tap(find.byType(CircularProgressIndicator));
    expect(btnTaps, 1);
  });

  test('WidgetService date, milestone, airport, and timezone formatting helpers', () {
    expect(
      WidgetService.formatTogetherBreakdown(DateTime(2025, 1, 10), DateTime(2026, 1, 9)),
      equals('0y 11m 30d'),
    );
    expect(
      WidgetService.formatTogetherBreakdown(DateTime(2026, 5, 1), DateTime(2026, 1, 1)),
      equals('0y 0m 0d'),
    );

    final m2500 = WidgetService.computeMilestoneProgress(2200);
    expect(m2500.nextTarget, equals(2500));
    expect(m2500.daysLeft, equals(300));

    expect(
      WidgetService.formatLastMetAgo(DateTime(2026, 5, 10), DateTime(2026, 5, 10)),
      equals('Last met today'),
    );
    expect(
      WidgetService.formatLastMetAgo(DateTime(2026, 5, 1), DateTime(2026, 5, 10)),
      equals('Last met 9d ago'),
    );
    expect(WidgetService.formatAirportCode('Frankfurt'), equals('FRA'));
    expect(WidgetService.formatAirportCode('Go'), equals('GO'));
    expect(WidgetService.formatTimezoneLabel(330), equals('UTC+5:30'));
    expect(WidgetService.formatTimezoneLabel(-300), equals('UTC-5'));
  });
}
