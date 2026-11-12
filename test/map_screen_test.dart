import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:nextmeet/core/constants.dart';
import 'package:nextmeet/core/models/memory_model.dart';
import 'package:nextmeet/core/models/relationship_model.dart';
import 'package:nextmeet/core/services/location_search_service.dart';
import 'package:nextmeet/features/home/shared_map_screen.dart';

class _TransparentTileProvider extends TileProvider {
  _TransparentTileProvider();

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return MemoryImage(TileProvider.transparentImage);
  }
}

void main() {
  group('SharedMapScreen coordinate, arc, city & style helpers', () {
    test('calculateArcPoints scales proportionally with distance and clamps polar latitudes', () {
      // Identical coordinates should not explode into an 8-degree northern loop
      final same = SharedMapScreen.calculateArcPoints(
        const LatLng(19.0760, 72.8777),
        const LatLng(19.0760, 72.8777),
      );
      expect(same.length, 2);
      expect(same.first.latitude, closeTo(19.0760, 1e-6));

      // Nearby couple (~10km apart, ~0.09 deg): arc deviates slightly, never 8 degrees north
      const nearStart = LatLng(19.0760, 72.8777);
      const nearEnd = LatLng(19.1660, 72.8777);
      final nearArc = SharedMapScreen.calculateArcPoints(nearStart, nearEnd);
      expect(nearArc.length, 31);
      final peakLat = nearArc.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
      expect(peakLat - nearEnd.latitude, lessThan(0.05));

      // Polar coordinates (>82 deg N): previously threw ArgumentError (> 90 deg)
      final polarArc = SharedMapScreen.calculateArcPoints(
        const LatLng(84.5, 12.0),
        const LatLng(85.0, 28.0),
      );
      for (final p in polarArc) {
        expect(p.latitude, inInclusiveRange(-85.0, 85.0));
        expect(p.longitude, inInclusiveRange(-180.0, 180.0));
      }
    });

    test('hasValidCoordinates accepts equator / Prime Meridian and rejects (0,0) sentinel', () {
      expect(SharedMapScreen.hasValidCoordinates(null, 10.0), isFalse);
      expect(SharedMapScreen.hasValidCoordinates(0.0, 0.0), isFalse);
      expect(SharedMapScreen.hasValidCoordinates(95.0, 10.0), isFalse);
      expect(SharedMapScreen.hasValidCoordinates(10.0, -181.0), isFalse);
      expect(SharedMapScreen.hasValidCoordinates(double.nan, 10.0), isFalse);

      // Valid Quito (lat 0) and Greenwich (lng 0)
      expect(SharedMapScreen.hasValidCoordinates(0.0, -78.4678), isTrue);
      expect(SharedMapScreen.hasValidCoordinates(51.4779, 0.0), isTrue);
    });

    test('resolveCityPoint & locationMatchesCity avoid short-token false positives', () {
      const fallback = LatLng(1.0, 2.0);
      // Short ambiguous substrings like "In" or "Go" must NOT match Berlin / Chicago
      expect(SharedMapScreen.resolveCityPoint('In', null, null, fallback), equals(fallback));
      expect(SharedMapScreen.resolveCityPoint('Go', null, null, fallback), equals(fallback));

      // Valid comma-delimited city string matches Mumbai accurately
      final mumbai = SharedMapScreen.resolveCityPoint('Mumbai, Maharashtra, India', null, null, fallback);
      expect(mumbai.latitude, closeTo(19.0760, 0.1));
      expect(mumbai.longitude, closeTo(72.8777, 0.1));

      expect(SharedMapScreen.locationMatchesCity('Dinner in Mumbai, India', 'Mumbai'), isTrue);
      expect(SharedMapScreen.locationMatchesCity('Paris, France', 'In'), isFalse);
    });

    test('buildArcPolylines & parseMapLineColor honor Neon, Solid, Dotted styles and hex colors', () {
      expect(SharedMapScreen.parseMapLineColor('#F59E0B'), equals(const Color(0xFFF59E0B)));
      expect(SharedMapScreen.parseMapLineColor('invalid'), equals(AppColors.primary));

      const pts = [LatLng(19.0, 72.8), LatLng(48.8, 2.3)];
      final neon = SharedMapScreen.buildArcPolylines(
        points: pts,
        hexColor: '#F59E0B',
        style: 'Neon',
      );
      expect(neon.length, 2);
      expect(neon.last.color, equals(const Color(0xFFF59E0B)));
      expect(neon.last.isDotted, isFalse);

      final dotted = SharedMapScreen.buildArcPolylines(
        points: pts,
        hexColor: '#8B5CF6',
        style: 'Dotted',
      );
      expect(dotted.length, 1);
      expect(dotted.first.isDotted, isTrue);

      final solid = SharedMapScreen.buildArcPolylines(
        points: pts,
        hexColor: '#10B981',
        style: 'Solid',
      );
      expect(solid.length, 1);
      expect(solid.first.isDotted, isFalse);
    });

    test('LocationResult.fromJson safely handles malformed coordinates', () {
      final invalid = LocationResult.fromJson({
        'display_name': 'Unknown Place',
        'lat': 'not-a-number',
        'lon': null,
      });
      expect(invalid.name, 'Unknown Place');
      expect(invalid.hasValidCoordinates, isFalse);

      final valid = LocationResult.fromJson({
        'display_name': 'Goa, India',
        'lat': '15.2993',
        'lon': '74.1240',
      });
      expect(valid.hasValidCoordinates, isTrue);
      expect(valid.lat, closeTo(15.2993, 0.0001));
    });
  });

  group('SharedMapScreen widget smoke, filtering & sheets', () {
    testWidgets('Renders cleanly under 1.5x text scaling, filters places & opens modals without overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final rel = RelationshipModel(
        id: 'rel_test_1',
        uid1: 'u1',
        uid2: 'u2',
        userName1: 'Aarav',
        userName2: 'Ananya',
        userLocation1: 'Mumbai',
        userLocation2: 'Paris',
        user1Lat: 19.0760,
        user1Lng: 72.8777,
        user2Lat: 48.8566,
        user2Lng: 2.3522,
        anniversaryDate: DateTime(2024, 2, 14),
        nextMeetingDate: DateTime(2026, 12, 20),
        lastMeetingDate: DateTime(2026, 1, 10),
        distanceKm: 7004.0,
        loveQuote: 'Every mile brings us closer.',
        tripDestination: 'Tokyo',
        tripDate: DateTime(2026, 12, 20),
        mapLineColor: '#F59E0B',
        mapLineStyle: 'Solid',
        coupleXp: 650,
      );

      final memories = [
        MemoryModel(
          id: 'mem_1',
          imageUrl: '',
          caption: 'Marine Drive Sunset',
          location: 'Mumbai, India',
          date: DateTime(2026, 1, 5),
          lat: 18.9438,
          lng: 72.8231,
        ),
        MemoryModel(
          id: 'mem_2',
          imageUrl: '',
          caption: 'Cherry Blossom Trip',
          location: 'Tokyo',
          date: DateTime(2026, 4, 2),
          moodEmoji: '✈️',
          lat: 35.6762,
          lng: 139.6503,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.5),
              ),
              child: SharedMapScreen(
                relId: 'rel_test_1',
                currentUidOverride: 'u1',
                relationshipStream: Stream.value(rel),
                memoriesStreamBuilder: (_) => Stream.value(memories),
                tileProvider: _TransparentTileProvider(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Core UI rendered
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.textContaining('km apart'), findsOneWidget);
      expect(find.text('© OpenStreetMap'), findsOneWidget);
      expect(find.text('Solid'), findsOneWidget);
      expect(find.text('Visited Places (5)'), findsOneWidget);

      // Scroll horizontal filter bar to reveal 'Trips' on narrow 360px 1.5x layout, then filter
      final filterList = find.byType(ListView).first;
      final tripsFilter = find.descendant(of: filterList, matching: find.text('Trips'));
      await tester.scrollUntilVisible(
        tripsFilter,
        100.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(tripsFilter);
      await tester.pumpAndSettle();
      expect(find.text('Visited Places (2)'), findsOneWidget);
      expect(find.text('Trip to Tokyo ✈️'), findsOneWidget);

      // Verify tapping a place card opens the Place Details sheet cleanly
      await tester.tap(find.text('Trip to Tokyo ✈️'));
      await tester.pumpAndSettle();
      expect(find.text('Add Memory at this Location'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Scroll filter bar back to reveal 'All places' and open See all modal
      final allPlacesFilter = find.descendant(of: filterList, matching: find.text('All places'));
      await tester.scrollUntilVisible(
        allPlacesFilter,
        -100.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(allPlacesFilter);
      await tester.pumpAndSettle();
      await tester.tap(find.text('See all'));
      await tester.pumpAndSettle();

      expect(find.text('All Visited Places (5)'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Tokyo');
      await tester.pump();
      expect(
        find.descendant(
          of: find.byType(ListTile),
          matching: find.text('Trip to Tokyo ✈️'),
        ),
        findsOneWidget,
      );
      // Clear search query inside modal and close via header close icon
      await tester.tap(find.byIcon(Icons.close_rounded).last);
      await tester.pump();
      expect(find.textContaining('Mumbai'), findsWidgets);

      await tester.tap(find.byIcon(Icons.close_rounded).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Solid').first);
      await tester.pumpAndSettle();
      expect(find.text('Map Path Style ✨'), findsOneWidget);
      expect(find.text('Gold'), findsOneWidget); // Unlocked at coupleXp 650 (Level 4)
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
    });
  });
}
