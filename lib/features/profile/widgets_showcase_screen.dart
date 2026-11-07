import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/models/relationship_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/widget_service.dart';
import '../../widgets/couple_widgets/couple_widgets.dart';
import '../../widgets/primary_button.dart';

/// NextMeet Home & Lock Screen Widgets Catalog Screen
/// Faithfully implementing NextMeet-widgets (WIDGET_SPEC.md & all-widgets.html)
class WidgetsShowcaseScreen extends StatefulWidget {
  const WidgetsShowcaseScreen({super.key});

  @override
  State<WidgetsShowcaseScreen> createState() => _WidgetsShowcaseScreenState();
}

class _WidgetsShowcaseScreenState extends State<WidgetsShowcaseScreen> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();

  int _selectedWidgetIndex = 0;
  String _selectedCategory = 'All';
  WidgetPalette _selectedPalette = WidgetPalette.pink;
  bool _isSyncing = false;

  // State variations for each widget
  DistanceBatteryState _distanceBatteryState = DistanceBatteryState.normal;
  HeartbeatWidgetState _heartbeatState = HeartbeatWidgetState.touching;
  CountdownWidgetState _countdownState = CountdownWidgetState.daysHours;
  MomentsWidgetState _momentsState = MomentsWidgetState.partnerMoment;
  GameWidgetState _gameState = GameWidgetState.yourMove;
  LoveNoteWidgetState _loveNoteState = LoveNoteWidgetState.normal;
  TripWidgetState _tripState = TripWidgetState.inTheAir;

  final List<Map<String, dynamic>> _allWidgets = [
    {
      'id': 'distance_battery',
      'title': 'Distance & Battery',
      'category': 'Medium',
      'size': 'Medium (4x2)',
      'desc': "Live distance in km, partner's battery % and local timezone",
      'icon': Icons.battery_charging_full_rounded,
      'color': const Color(0xFFD81B6A),
      'bg': const Color(0xFFFFE0ED),
    },
    {
      'id': 'heartbeat_sync',
      'title': 'Live Heartbeat Sync',
      'category': 'Small',
      'size': 'Small (2x2)',
      'desc': 'Pulse indicator showing when partner is touching their phone',
      'icon': Icons.favorite_rounded,
      'color': const Color(0xFF7B5CF0),
      'bg': const Color(0xFFEDE4FF),
    },
    {
      'id': 'reunion_countdown',
      'title': 'Reunion Countdown',
      'category': 'Medium',
      'size': 'Medium (4x2)',
      'desc': 'Days and hours remaining until your next flight or meetup',
      'icon': Icons.calendar_month_rounded,
      'color': const Color(0xFF1F7A4F),
      'bg': const Color(0xFFE3F6EC),
    },
    {
      'id': 'daily_moments',
      'title': 'Daily Moments Photo',
      'category': 'Large',
      'size': 'Large (4x4)',
      'desc': "Your partner's latest split moment photo directly on home screen",
      'icon': Icons.camera_alt_rounded,
      'color': const Color(0xFF7A5200),
      'bg': const Color(0xFFFFE7A3),
    },
    {
      'id': 'together_counter',
      'title': 'Together Counter',
      'category': 'Small',
      'size': 'Small (2x2)',
      'desc': 'Days together counter with leaning mascot hearts and breakdown',
      'icon': Icons.access_time_filled_rounded,
      'color': const Color(0xFF4B3A8C),
      'bg': const Color(0xFFEDE4FF),
    },
    {
      'id': 'quick_touch',
      'title': 'Quick Touch',
      'category': 'Small',
      'size': 'Small (2x2)',
      'desc': 'Send Miss you, Hug, Touch, or Cheer in 1 tap without opening app',
      'icon': Icons.touch_app_rounded,
      'color': const Color(0xFFD81B6A),
      'bg': const Color(0xFFFFE0ED),
    },
    {
      'id': 'two_clocks',
      'title': 'Two Clocks',
      'category': 'Wide',
      'size': 'Wide (4x1)',
      'desc': 'Both timezones side-by-side with distance in km on dotted line',
      'icon': Icons.schedule_rounded,
      'color': const Color(0xFFB0145A),
      'bg': const Color(0xFFFFF4F8),
    },
    {
      'id': 'next_milestone',
      'title': 'Next Milestone',
      'category': 'Small',
      'size': 'Small (2x2)',
      'desc': 'Circular progress ring counting down days to next milestone',
      'icon': Icons.donut_large_rounded,
      'color': const Color(0xFF5C4300),
      'bg': const Color(0xFFFFD66B),
    },
    {
      'id': 'game_status',
      'title': 'Game Status',
      'category': 'Small',
      'size': 'Small (2x2)',
      'desc': 'Live mini board showing active game turn with 1-tap Nudge',
      'icon': Icons.videogame_asset_rounded,
      'color': const Color(0xFF7B5CF0),
      'bg': const Color(0xFFEDE4FF),
    },
    {
      'id': 'love_note',
      'title': 'Love Note',
      'category': 'Medium',
      'size': 'Medium (4x2)',
      'desc': 'Latest love whisper or note snippet with photo preview',
      'icon': Icons.mark_email_unread_rounded,
      'color': const Color(0xFF4B3A8C),
      'bg': const Color(0xFFEDE4FF),
    },
    {
      'id': 'trip_tracker',
      'title': 'Trip Tracker',
      'category': 'Medium',
      'size': 'Medium (4x2)',
      'desc': 'Airport codes, dotted flight path, and arrival countdown',
      'icon': Icons.flight_takeoff_rounded,
      'color': const Color(0xFF1F7A4F),
      'bg': const Color(0xFFE3F6EC),
    },
    {
      'id': 'next_event',
      'title': 'Next Event',
      'category': 'Medium',
      'size': 'Medium (4x2)',
      'desc': 'Next two shared calendar events with category color bars',
      'icon': Icons.event_note_rounded,
      'color': const Color(0xFF7A6672),
      'bg': const Color(0xFFF1E4EA),
    },
    {
      'id': 'memory_of_the_day',
      'title': 'Memory of the Day',
      'category': 'Large',
      'size': 'Large (4x4)',
      'desc': 'Tilted polaroid frame showing a sweet memory from this date',
      'icon': Icons.photo_library_rounded,
      'color': const Color(0xFFB0145A),
      'bg': const Color(0xFFFFE0ED),
    },
    {
      'id': 'couple_dashboard',
      'title': 'Couple Dashboard',
      'category': 'Large',
      'size': 'Large (4x4)',
      'desc': 'Mega widget: partner status, dual times, distance, and quick touch',
      'icon': Icons.dashboard_rounded,
      'color': const Color(0xFFD81B6A),
      'bg': const Color(0xFFFFE0ED),
    },
  ];

  List<Map<String, dynamic>> get _filteredWidgets {
    if (_selectedCategory == 'All') return _allWidgets;
    return _allWidgets.where((w) => w['category'] == _selectedCategory).toList();
  }

  void _showReactionFeedback(String message) {
    VibrationService.success();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFD81B6A),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Future<void> _syncWidgets(RelationshipModel? rel, String currentUid) async {
    if (rel == null) return;
    setState(() => _isSyncing = true);
    VibrationService.medium();
    await WidgetService.updateWidgetData(rel, currentUid);
    if (!mounted) return;
    setState(() => _isSyncing = false);
    VibrationService.success();
    _showReactionFeedback('All 14 widgets synced to your phone! 📲✨');
  }

  void _showAddWidgetSheet(BuildContext context, RelationshipModel? rel, String currentUid) {
    VibrationService.light();
    final currentItem = _filteredWidgets[_selectedWidgetIndex.clamp(0, _filteredWidgets.length - 1)];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: currentItem['bg'] as Color,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(currentItem['icon'] as IconData, color: currentItem['color'] as Color, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentItem['title'] as String,
                          style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF2B1B26)),
                        ),
                        Text(
                          'Size: ${currentItem['size']}',
                          style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF7A6672)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _stepItem(1, 'Go to your phone\'s Home Screen'),
              _stepItem(2, 'Touch and hold an empty space on your wallpaper'),
              _stepItem(3, 'Tap "Widgets" and search for "NextMeet"'),
              _stepItem(4, 'Select "${currentItem['title']}" and place it on your screen!'),
              const SizedBox(height: 20),
              PrimaryButton(
                text: 'Sync Widget Data Now 🔄',
                isLoading: _isSyncing,
                onPressed: () {
                  Navigator.pop(ctx);
                  _syncWidgets(rel, currentUid);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepItem(int number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE0ED),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD81B6A), width: 1.2),
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: GoogleFonts.nunito(
                color: const Color(0xFFD81B6A),
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2B1B26),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateSelector(String widgetId) {
    switch (widgetId) {
      case 'distance_battery':
        return _buildChipRow<DistanceBatteryState>(
          current: _distanceBatteryState,
          options: const {
            DistanceBatteryState.normal: 'Normal',
            DistanceBatteryState.lowBattery: 'Low Battery (12%)',
            DistanceBatteryState.asleep: 'Probably Asleep (2:10 AM)',
          },
          onSelected: (val) => setState(() => _distanceBatteryState = val),
        );
      case 'heartbeat_sync':
        return _buildChipRow<HeartbeatWidgetState>(
          current: _heartbeatState,
          options: const {
            HeartbeatWidgetState.touching: 'Touching (74 bpm)',
            HeartbeatWidgetState.idle: 'Idle (Tap to send)',
            HeartbeatWidgetState.offline: 'Partner Offline',
          },
          onSelected: (val) => setState(() => _heartbeatState = val),
        );
      case 'reunion_countdown':
        return Column(
          children: [
            _buildChipRow<CountdownWidgetState>(
              current: _countdownState,
              options: const {
                CountdownWidgetState.daysHours: '23d 14h',
                CountdownWidgetState.tomorrow: 'Tomorrow',
                CountdownWidgetState.today: 'Today! 🎉',
              },
              onSelected: (val) => setState(() => _countdownState = val),
            ),
            const SizedBox(height: 8),
            _buildPaletteSelector(),
          ],
        );
      case 'daily_moments':
        return _buildChipRow<MomentsWidgetState>(
          current: _momentsState,
          options: const {
            MomentsWidgetState.partnerMoment: 'Partner Moment',
            MomentsWidgetState.waiting: 'Waiting for Partner',
            MomentsWidgetState.sent: 'Your Moment Sent',
          },
          onSelected: (val) => setState(() => _momentsState = val),
        );
      case 'game_status':
        return _buildChipRow<GameWidgetState>(
          current: _gameState,
          options: const {
            GameWidgetState.yourMove: 'Your Move (Play)',
            GameWidgetState.partnerTurn: "Partner's Turn (Nudge)",
          },
          onSelected: (val) => setState(() => _gameState = val),
        );
      case 'love_note':
        return _buildChipRow<LoveNoteWidgetState>(
          current: _loveNoteState,
          options: const {
            LoveNoteWidgetState.normal: 'Open Preview',
            LoveNoteWidgetState.sealed: 'Sealed Letter 🔒',
          },
          onSelected: (val) => setState(() => _loveNoteState = val),
        );
      case 'trip_tracker':
        return _buildChipRow<TripWidgetState>(
          current: _tripState,
          options: const {
            TripWidgetState.inTheAir: 'In the Air (62%)',
            TripWidgetState.scheduled: 'Scheduled (Boarding)',
            TripWidgetState.landed: 'Landed',
          },
          onSelected: (val) => setState(() => _tripState = val),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildChipRow<T>({
    required T current,
    required Map<T, String> options,
    required ValueChanged<T> onSelected,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.entries.map((entry) {
          final isSelected = current == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                entry.value,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : const Color(0xFF7A6672),
                ),
              ),
              selected: isSelected,
              selectedColor: const Color(0xFFD81B6A),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? const Color(0xFFD81B6A) : const Color(0xFFF8D8E6),
                  width: 1.5,
                ),
              ),
              onSelected: (_) {
                VibrationService.light();
                onSelected(entry.key);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaletteSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: WidgetPalette.values.map((p) {
        final colors = WidgetPaletteColors.of(p);
        final isSelected = _selectedPalette == p;

        return GestureDetector(
          onTap: () {
            VibrationService.light();
            setState(() => _selectedPalette = p);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? const Color(0xFF2B1B26) : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLiveWidgetPreview({
    required String widgetId,
    required String myName,
    required String partnerName,
    required int battery,
    required String distanceText,
    required String myTime,
    required String pTime,
    required RelationshipModel? rel,
  }) {
    final daysTogether = rel != null ? DateTime.now().difference(rel.anniversaryDate).inDays : 992;
    final years = daysTogether ~/ 365;
    final remainingDays = daysTogether % 365;
    final months = remainingDays ~/ 30;
    final days = remainingDays % 30;
    final breakdownStr = '${years}y ${months}m ${days}d';

    Widget childWidget;

    switch (widgetId) {
      case 'distance_battery':
        childWidget = DistanceBatteryWidget(
          distance: distanceText.isNotEmpty ? distanceText : '8,420 km',
          fromCity: rel?.getMyLocation(AuthService().currentUid ?? '').split(',').first.trim().isNotEmpty == true
              ? rel!.getMyLocation(AuthService().currentUid ?? '').split(',').first.trim()
              : 'Chennai',
          toCity: rel?.getPartnerLocation(AuthService().currentUid ?? '').split(',').first.trim().isNotEmpty == true
              ? rel!.getPartnerLocation(AuthService().currentUid ?? '').split(',').first.trim()
              : 'Frankfurt',
          partnerName: partnerName,
          battery: battery,
          timeText: 'CET, $pTime',
          state: _distanceBatteryState,
          onTap: () => _showReactionFeedback('Distance: $distanceText • Battery: $battery%'),
        );
        break;

      case 'heartbeat_sync':
        childWidget = HeartbeatSyncWidget(
          partnerName: partnerName,
          bpm: 74,
          state: _heartbeatState,
          onTap: () {
            VibrationService.medium();
            _showReactionFeedback('Sent heartbeat pulse to $partnerName! 💖');
          },
        );
        break;

      case 'reunion_countdown':
        childWidget = ReunionCountdownWidget(
          state: _countdownState,
          palette: _selectedPalette,
          countdownText: '23d 14h',
          subText: 'Wed 25 Nov, Frankfurt to Chennai',
          originAirport: 'FRA',
          destAirport: 'MAA',
          progress: 0.70,
          onTap: () => _showReactionFeedback('Reunion date: Wed 25 Nov ✈️'),
        );
        break;

      case 'daily_moments':
        final quote = rel?.loveQuote;
        final String momentCaption = (quote != null && quote.isNotEmpty)
            ? quote
            : 'Sunset without you. Miss you.';
        childWidget = DailyMomentsPhotoWidget(
          state: _momentsState,
          partnerName: partnerName,
          timeText: 'Today, 9:30 PM',
          caption: momentCaption,
          onHeartReact: () => _showReactionFeedback('Reacted with ❤️ to $partnerName\'s moment!'),
          onSendFirst: () => _showReactionFeedback('Ready to snap your moment! 📸'),
        );
        break;

      case 'together_counter':
        childWidget = TogetherCounterWidget(
          days: daysTogether,
          breakdown: breakdownStr,
          onTap: () => _showReactionFeedback('$daysTogether days together and counting! 💖'),
        );
        break;

      case 'quick_touch':
        childWidget = QuickTouchWidget(
          partnerName: partnerName,
          onAction: (action) {
            String label = 'Love touch';
            if (action == 'miss_you') label = 'Miss you ❤️';
            if (action == 'hug') label = 'Warm hug 🤗';
            if (action == 'touch') label = 'Tactile touch ✨';
            if (action == 'cheer') label = 'Cheer & sparkle ⭐';
            _showReactionFeedback('Sent "$label" to $partnerName!');
          },
        );
        break;

      case 'two_clocks':
        childWidget = TwoClocksWidget(
          myName: myName,
          myTime: myTime,
          partnerName: partnerName,
          partnerTime: pTime,
          distance: distanceText.isNotEmpty ? distanceText : '8,420 km',
          onTap: () => _showReactionFeedback('Clocks synced: $myTime vs $pTime'),
        );
        break;

      case 'next_milestone':
        childWidget = NextMilestoneWidget(
          daysLeft: 8,
          targetMilestone: '1000 days',
          progress: 0.92,
          onTap: () => _showReactionFeedback('8 days left to celebrate 1,000 days! 🎉'),
        );
        break;

      case 'game_status':
        childWidget = GameStatusWidget(
          partnerName: partnerName,
          state: _gameState,
          onAction: () {
            if (_gameState == GameWidgetState.yourMove) {
              _showReactionFeedback('Opening game turn! 🎮');
            } else {
              _showReactionFeedback('Nudged $partnerName to make their move! 🔔');
            }
          },
        );
        break;

      case 'love_note':
        childWidget = LoveNoteWidget(
          partnerName: partnerName,
          noteSnippet: 'Thinking of you, always.',
          timeAgo: '1 hr ago',
          state: _loveNoteState,
          onTap: () => _showReactionFeedback('Opening love note from $partnerName 💌'),
        );
        break;

      case 'trip_tracker':
        childWidget = TripTrackerWidget(
          state: _tripState,
          flightNumber: 'Flight XX 214',
          originCode: 'FRA',
          originCity: 'Frankfurt',
          destCode: 'MAA',
          destCity: 'Chennai',
          timeText: '12:30 PM',
          onTap: () => _showReactionFeedback('Tracking flight FRA ✈️ MAA'),
        );
        break;

      case 'next_event':
        childWidget = NextEventWidget(
          event1Title: 'Video call night',
          event1Sub: 'Tonight',
          event1Time: '9:30 PM',
          event2Title: 'Movie night',
          event2Sub: 'Fri 6 Nov, watch together',
          event2Time: '8:00 PM',
          onTap: () => _showReactionFeedback('Opening couple calendar 📅'),
        );
        break;

      case 'memory_of_the_day':
        childWidget = MemoryOfTheDayWidget(
          dateTitle: 'ON THIS DAY, 1 YEAR AGO',
          memoryTitle: 'Hill trek',
          memoryDate: '3 Nov 2025',
          onSeeMemory: () => _showReactionFeedback('Opening memory details 📸'),
        );
        break;

      case 'couple_dashboard':
      default:
        childWidget = CoupleDashboardWidget(
          partnerName: partnerName,
          battery: battery,
          streak: rel?.streakCount ?? 42,
          myTime: myTime,
          partnerTime: pTime,
          distance: distanceText.isNotEmpty ? distanceText : '8,420 km',
          meetupCountdown: '23d 14h',
          meetupDate: 'Wed 25 Nov',
          togetherDuration: breakdownStr,
          lastMet: 'Last met 3 mo ago',
          onHeartHold: () {
            VibrationService.medium();
            _showReactionFeedback('Heart held! Syncing with $partnerName... 💓');
          },
          onQuickTouch: (act) => _showReactionFeedback('Quick $act sent! ✨'),
        );
        break;
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: childWidget,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = AuthService().currentUid ?? '';

    return StreamBuilder<RelationshipModel?>(
      stream: _cloudService.streamRelationship(),
      builder: (context, snapshot) {
        final rel = snapshot.data;
        final myName = rel?.getMyName(currentUid) ?? 'You';
        final partnerName = rel?.getPartnerName(currentUid) ?? 'Partner';
        final battery = rel?.getPartnerBattery(currentUid) ?? 64;
        final dist = (rel?.computedDistance ?? 0) > 0 ? rel!.computedDistance : (rel?.distanceKm ?? 0);
        final distanceText = dist > 0
            ? '${NumberFormat("#,###").format(dist.round())} km'
            : '8,420 km';

        final now = DateTime.now();
        final myTime = DateFormat('h:mm a').format(now);
        final pOffset = rel?.getPartnerTimezoneOffset(currentUid) ?? 0;
        final pTime = DateFormat('h:mm a').format(now.toUtc().add(Duration(minutes: pOffset)));

        final filteredList = _filteredWidgets;
        final activeItem = filteredList[_selectedWidgetIndex.clamp(0, filteredList.length - 1)];

        return Scaffold(
          backgroundColor: const Color(0xFFFFF4F8),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),

                  // Top Navigation Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFF8D8E6), width: 1.5),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF2B1B26)),
                        ),
                      ),
                      Text(
                        'Couple Widgets',
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF2B1B26),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE0ED),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '14 Available',
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFD81B6A),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Size Category Filters
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'Small', 'Medium', 'Wide', 'Large'].map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              cat == 'All'
                                  ? 'All (14)'
                                  : (cat == 'Small'
                                      ? 'Small 2x2 (5)'
                                      : (cat == 'Medium'
                                          ? 'Medium 4x2 (5)'
                                          : (cat == 'Wide' ? 'Wide 4x1 (1)' : 'Large 4x4 (3)'))),
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: isSelected ? Colors.white : const Color(0xFF7A6672),
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: const Color(0xFFD81B6A),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? const Color(0xFFD81B6A) : const Color(0xFFF8D8E6),
                                width: 1.5,
                              ),
                            ),
                            onSelected: (_) {
                              VibrationService.light();
                              setState(() {
                                _selectedCategory = cat;
                                _selectedWidgetIndex = 0;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Interactive Hero Widget Preview
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    child: _buildLiveWidgetPreview(
                      widgetId: activeItem['id'] as String,
                      myName: myName,
                      partnerName: partnerName,
                      battery: battery,
                      distanceText: distanceText,
                      myTime: myTime,
                      pTime: pTime,
                      rel: rel,
                    ),
                  ),

                  // Dynamic State Variations Selector
                  _buildStateSelector(activeItem['id'] as String),

                  const SizedBox(height: 20),

                  // Catalog Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Widget Catalog',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF2B1B26),
                        ),
                      ),
                      Text(
                        '${filteredList.length} widgets',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF7A6672),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Widgets Catalog List
                  ...filteredList.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final widgetItem = entry.value;
                    final isSelected = _selectedWidgetIndex == idx;

                    return GestureDetector(
                      onTap: () {
                        VibrationService.light();
                        setState(() => _selectedWidgetIndex = idx);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFD81B6A) : const Color(0xFFF8D8E6),
                            width: isSelected ? 2.0 : 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: widgetItem['bg'] as Color,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                widgetItem['icon'] as IconData,
                                color: widgetItem['color'] as Color,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          widgetItem['title'] as String,
                                          style: GoogleFonts.nunito(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF2B1B26),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF4F8),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          widgetItem['size'] as String,
                                          style: GoogleFonts.nunito(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF7A6672),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widgetItem['desc'] as String,
                                    style: GoogleFonts.nunito(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF7A6672),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                              color: isSelected ? const Color(0xFFD81B6A) : const Color(0xFFF1D3E0),
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 16),

                  // Add to Home Screen Action Button
                  PrimaryButton(
                    text: 'Add to Home Screen 📲',
                    isLoading: _isSyncing,
                    onPressed: () => _showAddWidgetSheet(context, rel, currentUid),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
