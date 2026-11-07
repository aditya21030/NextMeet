import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nextmeet/core/cities.dart';
import 'package:nextmeet/core/constants.dart';
import 'package:nextmeet/widgets/flat_components.dart';
import 'package:nextmeet/widgets/primary_button.dart';

void main() {
  testWidgets('NextMeet Flat Components & Mascots Smoke Test', (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const MascotHeart(
                color: MascotColor.pink,
                size: 72,
                accessory: MascotAccessory.partyHat,
              ),
              const MascotHeart(
                color: MascotColor.violet,
                size: 72,
                accessory: MascotAccessory.crown,
              ),
              const TagChip(
                label: 'Online now',
                backgroundColor: AppColors.mintSoft,
                textColor: AppColors.mintText,
              ),
              const MetricTile(
                label: 'Together',
                value: '42 days',
                icon: Icons.favorite_rounded,
              ),
              PrimaryButton(
                text: 'Tap to connect',
                onPressed: () {
                  tapped = true;
                },
              ),
            ],
          ),
        ),
      ),
    );

    // Verify mascot hearts render
    expect(find.byType(MascotHeart), findsNWidgets(2));

    // Verify tag chip and metric tile text
    expect(find.text('Online now'), findsOneWidget);
    expect(find.text('TOGETHER'), findsOneWidget);
    expect(find.text('42 days'), findsOneWidget);

    // Verify button works
    expect(find.text('Tap to connect'), findsOneWidget);
    await tester.tap(find.text('Tap to connect'));
    expect(tapped, isTrue);
  });

  test('City distance calculation accuracy', () {
    // Mumbai (19.0760, 72.8777) to Paris (48.8566, 2.3522)
    final distance = CityData.calculateDistance(19.0760, 72.8777, 48.8566, 2.3522);
    expect(distance, greaterThan(6500));
    expect(distance, lessThan(7500));

    // Same point distance should be 0
    final zeroDist = CityData.calculateDistance(19.0760, 72.8777, 19.0760, 72.8777);
    expect(zeroDist, closeTo(0.0, 0.001));
  });
}
