import 'dart:async';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/constants.dart';
import '../../core/cities.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/premium_date_picker.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/location_search_service.dart';
import '../../core/models/relationship_model.dart';
import '../home/main_navigation_screen.dart';
import 'connection_success_screen.dart';
import '../../core/services/auth_error_handler.dart';

class CreateCoupleScreen extends StatefulWidget {
  final String? userName;
  const CreateCoupleScreen({super.key, this.userName});

  @override
  State<CreateCoupleScreen> createState() => _CreateCoupleScreenState();
}

class _CreateCoupleScreenState extends State<CreateCoupleScreen> {
  final _partnerNameController = TextEditingController();
  final _searchController = TextEditingController();
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  final LocationSearchService _locationSearchService = LocationSearchService();
  String _selectedCity = 'Mumbai';
  LocationResult? _selectedLocation;
  DateTime? _relationshipDate;
  bool _isCreated = false;
  bool _isGenerating = false;
  String _generatedCode = "";
  List<LocationResult> _searchResults = [];
  bool _isSearchingLocation = false;
  Timer? _searchTimer;
  StreamSubscription<RelationshipModel?>? _pairingSubscription;

  @override
  void dispose() {
    _pairingSubscription?.cancel();
    _searchTimer?.cancel();
    _partnerNameController.dispose();
    _searchController.dispose();
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
                      Text('Search for Your City, Town, or Village', style: AppTextStyles.h3),
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
                          
                          _searchTimer = Timer(const Duration(milliseconds: 600), () async {
                            final results = await _locationSearchService.search(val);
                            if (mounted) {
                              setModalState(() {
                                _searchResults = results;
                                _isSearchingLocation = false;
                              });
                            }
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'e.g. New York, London, or your town...',
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                          suffixIcon: _isSearchingLocation 
                              ? const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                )
                              : null,
                          fillColor: AppColors.background,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.m),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.l),
                      Expanded(
                        child: _searchResults.isEmpty && _searchController.text.length >= 2 && !_isSearchingLocation
                            ? Center(
                                child: Text('No places found. Check spelling? ❤️', style: AppTextStyles.bodyM),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: _searchResults.isEmpty ? CityData.majorCities.length : _searchResults.length,
                                itemBuilder: (context, index) {
                                  if (_searchResults.isEmpty) {
                                    final city = CityData.majorCities[index];
                                    return ListTile(
                                      leading: const Icon(Icons.location_city_rounded, color: AppColors.textSecondary),
                                      title: Text(city.name, style: AppTextStyles.bodyL),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Premium Mesh-like Background
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.08),
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
                        Text('Start Your Journey ✨', style: AppTextStyles.h1.copyWith(fontSize: 32)),
                        const SizedBox(height: 8),
                        Text(
                          'Fill in the magic details to sync hearts.',
                          style: AppTextStyles.bodyL.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  if (!_isCreated) ...[
                    // New "Skip for Now" option at top for extreme low friction
                    FadeInDown(
                      delay: const Duration(milliseconds: 50),
                      child: Center(
                        child: TextButton.icon(
                          onPressed: () => _handleCreateJourney(isSkip: true),
                          icon: const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 16),
                          label: Text(
                            'SKIP & GET CODE INSTANTLY ✨',
                            style: AppTextStyles.bodyS.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l),

                    // Input Section
                    FadeInUp(
                      delay: const Duration(milliseconds: 100),
                      child: _buildInteractiveCard(
                        title: 'What should I call your partner?',
                        subtitle: 'A sweet nickname just for your view ❤️',
                        icon: Icons.favorite_outline_rounded,
                        child: TextField(
                          controller: _partnerNameController,
                          style: AppTextStyles.bodyL.copyWith(fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: 'e.g. My Soulmate',
                            hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5)),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l),
                    FadeInUp(
                      delay: const Duration(milliseconds: 200),
                      child: _buildInteractiveCard(
                        title: 'Where are you right now?',
                        subtitle: 'Used to calculate distance between hearts',
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
                    FadeInUp(
                      delay: const Duration(milliseconds: 300),
                      child: _buildInteractiveCard(
                        title: 'When did your story start?',
                        subtitle: 'Your anniversary date',
                        icon: Icons.calendar_today_outlined,
                        onTap: () {
                          PremiumDatePicker.show(
                            context,
                            initialDate: _relationshipDate ?? DateTime.now(),
                            title: 'Anniversary Date',
                            onDateSelected: (date) {
                              setState(() => _relationshipDate = date);
                            },
                          );
                        },
                        child: Text(
                          _relationshipDate == null 
                              ? 'Tap to select date' 
                              : DateFormat('MMMM dd, yyyy').format(_relationshipDate!),
                          style: AppTextStyles.bodyL.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _relationshipDate == null ? AppColors.textSecondary : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    FadeInUp(
                      delay: const Duration(milliseconds: 400),
                      child: PrimaryButton(
                        text: 'Enter Our World ✨',
                        isLoading: _isGenerating,
                        onPressed: () => _handleCreateJourney(),
                      ),
                    ),
                  ] else ...[
                    // New Redesigned Code Display Section
                    FadeInUp(
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppRadius.xxl),
                              boxShadow: AppColors.premiumShadow,
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 24),
                                    const SizedBox(width: 12),
                                    Text(
                                      'It\'s a Match! ✨',
                                      style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 24),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.l),
                                Text(
                                  'Share this secret code with\n${_partnerNameController.text}',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.bodyL.copyWith(fontWeight: FontWeight.w700, height: 1.4),
                                ),
                                const SizedBox(height: AppSpacing.xl),
                                
                                // Enhanced Code Box with Copy
                                GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: _generatedCode));
                                    VibrationService.success();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Code copied to clipboard! ❤️'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(AppRadius.m),
                                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 2, style: BorderStyle.solid),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _generatedCode,
                                          style: AppTextStyles.h1.copyWith(
                                            fontSize: 32,
                                            letterSpacing: 8,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        const Icon(Icons.copy_rounded, color: AppColors.primary, size: 20),
                                      ],
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: AppSpacing.xl),
                                
                                // Social Sharing Row
                                Text(
                                  'SEND VIA',
                                  style: AppTextStyles.bodyS.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey),
                                ),
                                const SizedBox(height: AppSpacing.m),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildSocialBtn(
                                      icon: FontAwesomeIcons.whatsapp,
                                      color: AppColors.whatsapp,
                                      onTap: () => _shareToSocial('whatsapp'),
                                    ),
                                    _buildSocialBtn(
                                      icon: FontAwesomeIcons.telegram,
                                      color: AppColors.telegram,
                                      onTap: () => _shareToSocial('telegram'),
                                    ),
                                    _buildSocialBtn(
                                      icon: FontAwesomeIcons.instagram,
                                      color: AppColors.instagram,
                                      onTap: () => _shareToSocial('instagram'), // Note: Usually opens generic share or DM
                                    ),
                                    _buildSocialBtn(
                                      icon: Icons.more_horiz_rounded,
                                      color: Colors.grey.shade700,
                                      onTap: () => _shareToSocial('generic'),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: AppSpacing.xl),
                                Text(
                                  'They will enter this code to connect your hearts forever.',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl * 1.5),
                          PrimaryButton(
                            text: 'Enter Our World ✨',
                            onPressed: () {
                              VibrationService.success();
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
                                (route) => false,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
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
            const Divider(height: 32, color: AppColors.divider),
            child,
            if (onTap != null && child is! TextField) ...[
              const SizedBox(height: 12),
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

  Widget _buildSocialBtn({required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.circle),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  void _shareToSocial(String platform) async {
    final message = AppLinks.getInviteMessage(_generatedCode);
    VibrationService.medium();

    switch (platform) {
      case 'whatsapp':
        final url = "whatsapp://send?text=${Uri.encodeComponent(message)}";
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url));
        } else {
          Share.share(message);
        }
        break;
      case 'telegram':
        final url = "tg://msg?text=${Uri.encodeComponent(message)}";
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url));
        } else {
          Share.share(message);
        }
        break;
      default:
        Share.share(message, subject: 'NextMeet Love Invite');
    }
  }

  Future<void> _handleCreateJourney({bool isSkip = false}) async {
    setState(() => _isGenerating = true);
    VibrationService.medium();

    try {
      final name = _partnerNameController.text.trim().isEmpty ? 'Soulmate' : _partnerNameController.text.trim();
      final anniversary = _relationshipDate ?? DateTime.now();
      
      final code = await _cloudService.createJourney(
        RelationshipModel(
          userName1: widget.userName ?? 'You', 
          user1PartnerNickname: name, 
          anniversaryDate: anniversary,
          nextMeetingDate: DateTime.now().add(const Duration(days: 30)),
          distanceKm: 0,
          userLocation1: _selectedCity,
          user1Lat: _selectedLocation?.lat,
          user1Lng: _selectedLocation?.lng,
          userLocation2: 'Remote',
          userMood1: 'Happy 💖',
          lastMeetingDate: DateTime.now(),
          loveQuote: 'Every day apart is one day closer ❤️',
        ),
      );

      if (mounted) {
        setState(() {
          _generatedCode = code;
          _isCreated = true;
          _isGenerating = false;
        });
        VibrationService.success();

        // Step 2.4: Real-time pairing listener
        _pairingSubscription?.cancel();
        _pairingSubscription = _cloudService.streamRelationship().listen((rel) {
          if (!mounted) return;
          if (rel != null && rel.status == 'active' && rel.uid2 != null) {
            _pairingSubscription?.cancel();
            VibrationService.success();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const ConnectionSuccessScreen()),
              (route) => false,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isGenerating = false);
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
}
