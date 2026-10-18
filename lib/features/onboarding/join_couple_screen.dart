import 'dart:async';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import '../../core/constants.dart';
import '../../core/cities.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/primary_button.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/location_search_service.dart';
import 'connection_success_screen.dart';
import 'create_couple_screen.dart';
import '../../core/services/auth_error_handler.dart';

class JoinCoupleScreen extends StatefulWidget {
  final String? userName;
  final String? initialCode;
  const JoinCoupleScreen({super.key, this.userName, this.initialCode});

  @override
  State<JoinCoupleScreen> createState() => _JoinCoupleScreenState();
}

class _JoinCoupleScreenState extends State<JoinCoupleScreen> {
  final _pinController = TextEditingController();
  final _partnerPetNameController = TextEditingController();
  final _searchController = TextEditingController();
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  final LocationSearchService _locationSearchService = LocationSearchService();
  final _focusNode = FocusNode();
  String _selectedCity = 'Bengaluru';
  LocationResult? _selectedLocation;
  List<LocationResult> _searchResults = [];
  bool _isSearchingLocation = false;
  Timer? _searchTimer;
  bool _isConnecting = false;
  bool _isCodeAutoDetected = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialCode != null && widget.initialCode!.isNotEmpty) {
      _pinController.text = widget.initialCode!;
      _isCodeAutoDetected = true;
    } else {
      _checkClipboardForCode();
    }
  }

  Future<void> _checkClipboardForCode() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim();
      if (text != null && text.isNotEmpty) {
        final match = RegExp(r'\b\d{6}\b').firstMatch(text);
        if (match != null && mounted) {
          final code = match.group(0)!;
          setState(() {
            _pinController.text = code;
            _isCodeAutoDetected = true;
          });
          VibrationService.light();
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _pinController.dispose();
    _partnerPetNameController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _showCitySearch() {
    VibrationService.light();
    _searchController.clear();
    _searchResults = [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.8,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.l),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.l),
                      Text('Select Your City or Location', style: AppTextStyles.h3),
                      const SizedBox(height: AppSpacing.m),
                      TextField(
                        controller: _searchController,
                        autofocus: true,
                        onChanged: (val) {
                          if (_searchTimer?.isActive ?? false) _searchTimer!.cancel();
                          if (val.length < 2) {
                            setModalState(() {
                              _searchResults = [];
                              _isSearchingLocation = false;
                            });
                            return;
                          }
                          setModalState(() => _isSearchingLocation = true);
                          _searchTimer = Timer(const Duration(milliseconds: 300), () async {
                            final results = await _locationSearchService.searchCities(val);
                            setModalState(() {
                              _searchResults = results;
                              _isSearchingLocation = false;
                            });
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search city, town, or state...',
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.l),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.m),
                      Expanded(
                        child: _isSearchingLocation
                            ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: _searchController.text.length < 2 ? CityData.indianCities.length : _searchResults.length,
                                itemBuilder: (context, index) {
                                  if (_searchController.text.length < 2) {
                                    final city = CityData.indianCities[index];
                                    return ListTile(
                                      leading: const Icon(Icons.location_city_rounded, color: AppColors.textSecondary),
                                      title: Text(city.name, style: AppTextStyles.bodyM),
                                      onTap: () {
                                        VibrationService.light();
                                        setState(() {
                                          _selectedCity = city.name;
                                          _selectedLocation = LocationResult(name: city.name, lat: city.lat, lng: city.lng);
                                        });
                                        Navigator.pop(context);
                                      },
                                    );
                                  } else {
                                    final loc = _searchResults[index];
                                    return ListTile(
                                      leading: const Icon(Icons.place_rounded, color: AppColors.primary),
                                      title: Text(loc.name, style: AppTextStyles.bodyM, maxLines: 2, overflow: TextOverflow.ellipsis),
                                      onTap: () {
                                        VibrationService.light();
                                        setState(() {
                                          _selectedCity = loc.name.split(',').first.trim();
                                          _selectedLocation = loc;
                                        });
                                        Navigator.pop(context);
                                      },
                                    );
                                  }
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _handleJoin() async {
    final code = _pinController.text.trim();
    if (code.length < 6) {
      VibrationService.error();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the full 6-digit invite code ❤️'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isConnecting = true);
    VibrationService.medium();

    try {
      final relationship = await _cloudService.joinJourney(
        code,
        _selectedCity,
        widget.userName ?? 'Partner',
        _partnerPetNameController.text.trim().isEmpty ? 'Partner' : _partnerPetNameController.text.trim(),
        lat: _selectedLocation?.lat,
        lng: _selectedLocation?.lng,
      );

      if (mounted) {
        if (relationship != null) {
          VibrationService.success();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ConnectionSuccessScreen()),
          );
        } else {
          setState(() => _isConnecting = false);
          VibrationService.error();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Invalid code or connection expired. Please check with your partner ❤️'),
              backgroundColor: const Color(0xFFE11D48),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isConnecting = false);
      VibrationService.error();
      if (mounted) {
        final friendlyMsg = AuthErrorHandler.getJourneyErrorMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyMsg),
            backgroundColor: const Color(0xFFE11D48),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 48,
      height: 56,
      textStyle: AppTextStyles.h1.copyWith(color: AppColors.primary, fontSize: 24, letterSpacing: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.m),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.8), width: 1.5),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Ambient Glow
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.06),
                    AppColors.primary.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInDown(
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),
                  FadeInLeft(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Connect to Partner ❤️', style: AppTextStyles.h1.copyWith(fontSize: 30)),
                        const SizedBox(height: 8),
                        Text(
                          'Enter the 6-digit invite code shared by your partner.',
                          style: AppTextStyles.bodyL.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Detected code notification banner
                  if (_isCodeAutoDetected)
                    FadeInDown(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.l),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Invite code auto-filled from your clipboard ✨',
                                style: TextStyle(
                                  color: const Color(0xFF065F46),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Pin Input Card
                  FadeInUp(
                    delay: const Duration(milliseconds: 100),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.xxl),
                        boxShadow: AppColors.softShadow,
                        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.key_rounded, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                '6-Digit Love Invite Code',
                                style: AppTextStyles.bodyM.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Enter code received via WhatsApp or text',
                              style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                          const Divider(height: 28, color: AppColors.divider),
                          const SizedBox(height: AppSpacing.s),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Pinput(
                              length: 6,
                              controller: _pinController,
                              focusNode: _focusNode,
                              defaultPinTheme: defaultPinTheme,
                              focusedPinTheme: defaultPinTheme.copyWith(
                                decoration: defaultPinTheme.decoration!.copyWith(
                                  border: Border.all(color: AppColors.primary, width: 2),
                                ),
                              ),
                              hapticFeedbackType: HapticFeedbackType.mediumImpact,
                              onCompleted: (pin) => _handleJoin(),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.m),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),

                  // City Selection (Computes accurate couple distance)
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    child: _buildInteractiveCard(
                      title: 'Your City or Location',
                      subtitle: 'Used to calculate live distance between hearts',
                      icon: Icons.location_on_outlined,
                      onTap: _showCitySearch,
                      child: Text(
                        _selectedCity,
                        style: AppTextStyles.bodyL.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),

                  // Optional Partner Nickname
                  FadeInUp(
                    delay: const Duration(milliseconds: 300),
                    child: _buildInteractiveCard(
                      title: "Partner's Name or Nickname (Optional)",
                      subtitle: 'How you want your partner to appear in your space',
                      icon: Icons.favorite_outline_rounded,
                      child: TextField(
                        controller: _partnerPetNameController,
                        style: AppTextStyles.bodyL.copyWith(fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: 'e.g. My Soulmate',
                          hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5)),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  if (_isConnecting)
                    FadeInUp(
                      child: Center(
                        child: Column(
                          children: [
                            const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
                            const SizedBox(height: AppSpacing.m),
                            Text(
                              'Connecting your shared space...',
                              style: AppTextStyles.bodyM.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    FadeInUp(
                      delay: const Duration(milliseconds: 400),
                      child: PrimaryButton(
                        text: 'Connect Hearts ❤️',
                        onPressed: _handleJoin,
                      ),
                    ),

                  const SizedBox(height: AppSpacing.xl),
                  FadeInUp(
                    delay: const Duration(milliseconds: 500),
                    child: Center(
                      child: TextButton(
                        onPressed: () {
                          VibrationService.light();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateCoupleScreen(userName: widget.userName),
                            ),
                          );
                        },
                        child: Text(
                          "Don't have a code? Create your space instead",
                          style: AppTextStyles.bodyM.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          boxShadow: AppColors.softShadow,
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.bodyM.copyWith(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary),
            ),
            const Divider(height: 28, color: AppColors.divider),
            child,
            if (onTap != null && child is! TextField) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Change', style: AppTextStyles.bodyS.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 16),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
