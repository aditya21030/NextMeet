import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants.dart';
import '../../core/models/relationship_model.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../widgets/flat_components.dart';
import '../../widgets/primary_button.dart';
import '../home/main_navigation_screen.dart';
import 'connection_success_screen.dart';

/// Step 3 / 3: Find Your Other Half (Pairing Screen)
/// Strictly following NextMeet Redesign.pdf (Page 9)
class FindYourOtherHalfScreen extends StatefulWidget {
  final String userName;
  final String nickname;
  final MascotColor mascotColor;
  final String yourCity;
  final String theirCity;
  final DateTime togetherSince;
  final DateTime lastTimeMet;
  final DateTime? nextMeetup;
  final String? initialInviteCode;

  const FindYourOtherHalfScreen({
    super.key,
    required this.userName,
    required this.nickname,
    required this.mascotColor,
    required this.yourCity,
    required this.theirCity,
    required this.togetherSince,
    required this.lastTimeMet,
    this.nextMeetup,
    this.initialInviteCode,
  });

  @override
  State<FindYourOtherHalfScreen> createState() => _FindYourOtherHalfScreenState();
}

class _FindYourOtherHalfScreenState extends State<FindYourOtherHalfScreen> {
  late String _myInviteCode;
  final _partnerCodeController = TextEditingController();
  bool _isConnecting = false;
  final CloudRelationshipService _relService = CloudRelationshipService();
  StreamSubscription<RelationshipModel?>? _relSubscription;

  @override
  void initState() {
    super.initState();
    // Generate a random 6-digit code or read initial code
    final rnd = Random();
    _myInviteCode = (100000 + rnd.nextInt(900000)).toString();

    if (widget.initialInviteCode != null && widget.initialInviteCode!.length == 6) {
      _partnerCodeController.text = widget.initialInviteCode!;
    } else {
      _registerJourneyCode();
    }

    _listenForPartnerJoin();
  }

  void _listenForPartnerJoin() {
    _relSubscription?.cancel();
    _relSubscription = _relService.streamRelationship().listen((rel) {
      if (!mounted) return;
      if (rel != null && rel.status == 'active' && rel.uid2 != null) {
        _relSubscription?.cancel();
        VibrationService.success();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ConnectionSuccessScreen(
              relationship: rel,
            ),
          ),
        );
      }
    });
  }

  Future<void> _registerJourneyCode() async {
    try {
      final code = await _relService.createJourney(
        RelationshipModel(
          userName1: widget.userName,
          userLocation1: widget.yourCity,
          userLocation2: widget.theirCity,
          user1PartnerNickname: widget.nickname.isNotEmpty ? widget.nickname : 'Love',
          anniversaryDate: widget.togetherSince,
          lastMeetingDate: widget.lastTimeMet,
          nextMeetingDate: widget.nextMeetup ?? DateTime.now().add(const Duration(days: 23)),
          distanceKm: 0.0,
          loveQuote: 'Close, even when you are apart.',
        ),
      );
      if (mounted) {
        setState(() {
          _myInviteCode = code;
        });
      }
    } catch (e) {
      debugPrint('Error starting journey: $e');
    }
  }

  @override
  void dispose() {
    _relSubscription?.cancel();
    _partnerCodeController.dispose();
    super.dispose();
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _myInviteCode));
    VibrationService.success();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code copied to clipboard! Share it with your love ❤️'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _shareCode() {
    VibrationService.light();
    Share.share(AppLinks.getInviteMessage(_myInviteCode));
  }

  Future<void> _handleConnect() async {
    final code = _partnerCodeController.text.trim();
    if (code.length != 6) {
      VibrationService.error();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 6-digit partner code'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isConnecting = true);
    VibrationService.medium();

    try {
      final relationship = await _relService.joinJourney(
        code,
        widget.yourCity.isNotEmpty ? widget.yourCity : widget.theirCity,
        widget.userName,
        widget.nickname.isNotEmpty ? widget.nickname : 'Love',
      );

      if (!mounted) return;
      setState(() => _isConnecting = false);

      if (relationship != null) {
        VibrationService.success();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ConnectionSuccessScreen(
              relationship: relationship,
            ),
          ),
        );
      } else {
        VibrationService.error();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not find a journey with that code. Please check and try again.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isConnecting = false);
      VibrationService.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error connecting: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary, // Pink header
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation & 3 / 3 Progress Indicator
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
                      Container(width: 48, height: 4, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))),
                    ],
                  ),
                  Text(
                    '3 / 3',
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
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Find your other half',
                      style: AppTextStyles.display.copyWith(color: Colors.white, fontSize: 30),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Share your code or type theirs.',
                      style: AppTextStyles.body.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                    ),
                  ],
                ),
              ),
            ),

            // Mascots with Gold Keyhole Link (Page 9)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const MascotHeart(color: MascotColor.pink, size: 68, leanRight: true),
                  const SizedBox(width: 8),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: AppColors.butter,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.key_rounded, color: AppColors.butterText, size: 16),
                  ),
                  const SizedBox(width: 8),
                  const MascotHeart(color: MascotColor.violet, size: 68, leanLeft: true),
                ],
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
                      // Card 1: Your invite code
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: AppColors.border, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Your invite code', style: AppTextStyles.label.copyWith(color: AppColors.ink)),
                            const SizedBox(height: 12),
                            // 6 Code Digits
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: _myInviteCode.split('').map((char) {
                                return Container(
                                  width: 44,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.border, width: 1.5),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    char,
                                    style: AppTextStyles.display.copyWith(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 14),
                            // Copy & Share Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _copyCode,
                                    child: Container(
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppColors.pinkSoft,
                                        borderRadius: BorderRadius.circular(AppRadius.pill),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Copy',
                                        style: AppTextStyles.button.copyWith(
                                          color: AppColors.primary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _shareCode,
                                    child: Container(
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(AppRadius.pill),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Share',
                                        style: AppTextStyles.button.copyWith(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Card 2: Their invite code
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: AppColors.border, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Their invite code', style: AppTextStyles.label.copyWith(color: AppColors.ink)),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _partnerCodeController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.display.copyWith(
                                fontSize: 26,
                                letterSpacing: 8,
                                color: AppColors.primary,
                              ),
                              decoration: const InputDecoration(
                                hintText: '••••••',
                                counterText: '',
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Card 3: About you two
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: AppColors.border, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('About you two', style: AppTextStyles.label.copyWith(color: AppColors.ink)),
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Text(
                                    'Edit',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Your city', style: AppTextStyles.caption),
                                      Text(
                                        widget.yourCity,
                                        style: AppTextStyles.heading.copyWith(fontSize: 15),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Their city', style: AppTextStyles.caption),
                                      Text(
                                        widget.theirCity,
                                        style: AppTextStyles.heading.copyWith(fontSize: 15),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Quick chips row
                            Builder(
                              builder: (context) {
                                final daysTogether = DateTime.now().difference(widget.togetherSince).inDays;
                                final togetherStr = daysTogether <= 0
                                    ? 'Together 1 day'
                                    : (daysTogether >= 365
                                        ? 'Together ${daysTogether ~/ 365}y ${(daysTogether % 365) ~/ 30}m'
                                        : 'Together $daysTogether days');

                                final daysSinceMet = DateTime.now().difference(widget.lastTimeMet).inDays;
                                final metStr = daysSinceMet <= 0
                                    ? 'Met today'
                                    : (daysSinceMet < 30 ? 'Met ${daysSinceMet}d ago' : 'Met ${daysSinceMet ~/ 30}mo ago');

                                return Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    TagChip(label: togetherStr, backgroundColor: AppColors.pinkSoft),
                                    TagChip(label: metStr, backgroundColor: AppColors.butterSoft, textColor: AppColors.butterText),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Connect CTA
                      PrimaryButton(
                        text: 'Connect',
                        isLoading: _isConnecting,
                        onPressed: _handleConnect,
                      ),
                      const SizedBox(height: 12),

                      // I will do this later
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
                              (route) => false,
                            );
                          },
                          child: Text(
                            'I will do this later',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
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
}
