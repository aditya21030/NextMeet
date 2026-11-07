import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/location_search_service.dart';
import '../../widgets/flat_components.dart';
import '../../widgets/primary_button.dart';
import 'permissions_screen.dart';

/// Step 2 / 3: Your Story
/// Strictly following NextMeet Redesign.pdf (Page 7)
class YourStoryScreen extends StatefulWidget {
  final String userName;
  final String nickname;
  final MascotColor mascotColor;
  final String? initialInviteCode;

  const YourStoryScreen({
    super.key,
    required this.userName,
    required this.nickname,
    required this.mascotColor,
    this.initialInviteCode,
  });

  @override
  State<YourStoryScreen> createState() => _YourStoryScreenState();
}

class _YourStoryScreenState extends State<YourStoryScreen> {
  final _yourCityController = TextEditingController();
  final _theirCityController = TextEditingController();

  DateTime _togetherSince = DateTime.now().subtract(const Duration(days: 365));
  DateTime _lastTimeMet = DateTime.now().subtract(const Duration(days: 30));
  DateTime? _nextMeetup = DateTime.now().add(const Duration(days: 14));

  bool _isLocating = false;

  @override
  void dispose() {
    _yourCityController.dispose();
    _theirCityController.dispose();
    super.dispose();
  }

  Future<void> _handleUseLocation() async {
    setState(() => _isLocating = true);
    VibrationService.light();

    try {
      final city = await LocationSearchService.getCurrentCity();
      if (city != null && mounted) {
        setState(() => _yourCityController.text = city);
        VibrationService.success();
      }
    } catch (_) {}

    if (mounted) setState(() => _isLocating = false);
  }

  Future<void> _pickDate({
    required BuildContext context,
    required DateTime initialDate,
    required Function(DateTime) onPicked,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    VibrationService.light();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      VibrationService.light();
      setState(() => onPicked(picked));
    }
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String get _togetherDurationText {
    final diff = DateTime.now().difference(_togetherSince);
    final years = (diff.inDays / 365).floor();
    final months = ((diff.inDays % 365) / 30).floor();
    if (years > 0 && months > 0) return '$years years $months months';
    if (years > 0) return '$years year${years > 1 ? 's' : ''}';
    return '$months month${months > 1 ? 's' : ''}';
  }

  void _handleContinue() {
    VibrationService.light();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PermissionsScreen(
          userName: widget.userName,
          nickname: widget.nickname,
          mascotColor: widget.mascotColor,
          yourCity: _yourCityController.text.trim(),
          theirCity: _theirCityController.text.trim(),
          togetherSince: _togetherSince,
          lastTimeMet: _lastTimeMet,
          nextMeetup: _nextMeetup,
          initialInviteCode: widget.initialInviteCode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.partner, // Purple header canvas
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation & 2 / 3 Progress Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                  Row(
                    children: [
                      Container(width: 48, height: 4, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 6),
                      Container(width: 48, height: 4, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 6),
                      Container(width: 48, height: 4, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
                    ],
                  ),
                  Text(
                    '2 / 3',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            // Header Titles
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your story',
                      style: AppTextStyles.display.copyWith(color: Colors.white, fontSize: 30),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Where you are and how far you have come.',
                      style: AppTextStyles.body.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                    ),
                  ],
                ),
              ),
            ),

            // Form Sheet
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Your city
                      _inputCard(
                        icon: Icons.location_on_outlined,
                        iconColor: AppColors.primary,
                        label: 'Your city',
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _yourCityController,
                                style: AppTextStyles.heading.copyWith(fontSize: 16),
                                decoration: const InputDecoration(
                                  hintText: 'e.g. London',
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _handleUseLocation,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.pinkSoft,
                                  borderRadius: BorderRadius.circular(AppRadius.badge),
                                ),
                                child: _isLocating
                                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                                    : Text(
                                        'Use location',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 2. Their city
                      _inputCard(
                        icon: Icons.location_on_outlined,
                        iconColor: AppColors.partner,
                        label: 'Their city',
                        child: TextFormField(
                          controller: _theirCityController,
                          style: AppTextStyles.heading.copyWith(fontSize: 16),
                          decoration: const InputDecoration(
                            hintText: "e.g. Paris",
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 3. Together since
                      _inputCard(
                        icon: Icons.calendar_today_outlined,
                        iconColor: AppColors.primary,
                        label: 'Together since',
                        onTap: () => _pickDate(
                          context: context,
                          initialDate: _togetherSince,
                          lastDate: DateTime.now(),
                          onPicked: (d) => _togetherSince = d,
                        ),
                        child: Text(
                          _formatDate(_togetherSince),
                          style: AppTextStyles.heading.copyWith(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 4. Last time you met
                      _inputCard(
                        icon: Icons.check_rounded,
                        iconColor: AppColors.primary,
                        label: 'Last time you met',
                        onTap: () => _pickDate(
                          context: context,
                          initialDate: _lastTimeMet,
                          lastDate: DateTime.now(),
                          onPicked: (d) => _lastTimeMet = d,
                        ),
                        child: Text(
                          _formatDate(_lastTimeMet),
                          style: AppTextStyles.heading.copyWith(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 5. Next meetup (optional)
                      _inputCard(
                        icon: Icons.send_rounded,
                        iconColor: AppColors.primary,
                        label: 'Next meetup (optional)',
                        onTap: () => _pickDate(
                          context: context,
                          initialDate: _nextMeetup ?? DateTime.now().add(const Duration(days: 20)),
                          firstDate: DateTime.now(),
                          onPicked: (d) => _nextMeetup = d,
                        ),
                        child: Text(
                          _nextMeetup != null ? _formatDate(_nextMeetup!) : 'Not planned yet',
                          style: AppTextStyles.heading.copyWith(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Real-time Summary Card (Page 7)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.partnerSoft.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: AppColors.partnerTint, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Together for $_togetherDurationText',
                                    style: AppTextStyles.heading.copyWith(
                                      fontSize: 15,
                                      color: AppColors.partnerText,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    () {
                                      final daysAgo = DateTime.now().difference(_lastTimeMet).inDays;
                                      if (daysAgo <= 0) return 'Last met today';
                                      if (daysAgo < 30) return 'Last met $daysAgo days ago';
                                      return 'Last met ${daysAgo ~/ 30} months ago';
                                    }(),
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.partnerText.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Continue CTA
                      PrimaryButton(
                        text: 'Continue',
                        onPressed: _handleContinue,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Widget child,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.input),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.muted, fontSize: 12)),
                  const SizedBox(height: 2),
                  child,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
