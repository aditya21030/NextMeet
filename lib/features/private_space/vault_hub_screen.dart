import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/security_service.dart';
import '../../core/models/relationship_model.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../widgets/flat_components.dart';
import 'love_letters_screen.dart';
import 'voice_whispers_screen.dart';
import 'secret_photos_gallery_screen.dart';
import 'reset_vault_pin_screen.dart';
import 'create_vault_pin_screen.dart';
import 'private_space_settings_screen.dart';

/// NextMeet Vault Tab Hub Screen
/// Strictly following NextMeet Redesign.pdf (Pages 58 & 61)
class VaultHubScreen extends StatefulWidget {
  const VaultHubScreen({super.key});

  @override
  State<VaultHubScreen> createState() => VaultHubScreenState();
}

class VaultHubScreenState extends State<VaultHubScreen> {
  bool _isUnlocked = false;
  String _enteredPin = '';
  final String _defaultPin = '1234';
  int _selectedFilter = 0; // 0: All, 1: Us, 2: Trips, 3: Secrets
  bool _isVerifying = false;

  final CloudRelationshipService _cloudService = CloudRelationshipService();

  void lock() {
    if (mounted) {
      setState(() {
        _isUnlocked = false;
        _enteredPin = '';
      });
    }
  }

  void _onDigit(String d, RelationshipModel? rel) {
    if (_isVerifying) return;
    if (_enteredPin.length < 4) {
      VibrationService.light();
      setState(() {
        _enteredPin += d;
      });
      if (_enteredPin.length == 4) {
        _verifyPin(rel);
      }
    }
  }

  void _onBackspace() {
    if (_isVerifying) return;
    if (_enteredPin.isNotEmpty) {
      VibrationService.light();
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  Future<void> _verifyPin(RelationshipModel? rel) async {
    setState(() => _isVerifying = true);
    final prefs = await SharedPreferences.getInstance();
    final localPin = prefs.getString('vault_pin');
    final activePin = (rel?.privateSpacePin != null && rel!.privateSpacePin!.isNotEmpty)
        ? rel.privateSpacePin!
        : (localPin != null && localPin.isNotEmpty ? localPin : _defaultPin);

    if (_enteredPin == activePin) {
      VibrationService.success();
      if (!mounted) return;
      setState(() {
        _isUnlocked = true;
        _enteredPin = '';
        _isVerifying = false;
      });
    } else {
      VibrationService.error();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect PIN. Please try again or ask partner to reset.'),
          backgroundColor: AppColors.danger,
          duration: Duration(seconds: 2),
        ),
      );
      setState(() {
        _enteredPin = '';
        _isVerifying = false;
      });
    }
  }

  Future<void> _handleBiometricUnlock() async {
    VibrationService.light();
    final result = await SecurityService().authenticateWithDetails(
      reason: 'Scan fingerprint to open your private Vault',
      biometricOnly: false,
    );
    if (!mounted) return;
    if (result.success) {
      VibrationService.success();
      setState(() => _isUnlocked = true);
    } else if (result.errorMessage != null && result.errorCode != 'UserCanceled') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage!),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RelationshipModel?>(
      stream: _cloudService.streamRelationship(),
      builder: (context, snapshot) {
        final rel = snapshot.data;
        if (!_isUnlocked) {
          return _buildLockScreen(rel);
        }
        return _buildUnlockedGalleryScreen(rel);
      },
    );
  }

  // Page 58: Enter PIN Lock Screen
  Widget _buildLockScreen(RelationshipModel? rel) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
            // Top Bar: Vault + Encrypted Pill
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Vault', style: AppTextStyles.display.copyWith(fontSize: 26)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.partnerSoft,
                      borderRadius: BorderRadius.circular(AppRadius.badge),
                    ),
                    child: Text(
                      'Encrypted',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.partnerText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Pink Lock Mascot with Heart Keyhole (Page 58)
            Center(
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: -12,
                      child: Container(
                        width: 50,
                        height: 40,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.partner, width: 8),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                        ),
                      ),
                    ),
                    const Icon(Icons.favorite_rounded, color: Colors.white, size: 28),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Your secret space',
              style: AppTextStyles.display.copyWith(fontSize: 24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Enter your PIN to open your private photos.',
              style: AppTextStyles.body.copyWith(color: AppColors.muted),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // 4 PIN Dots (Page 58)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _enteredPin.length;
                return Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: isFilled ? AppColors.primary : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isFilled ? AppColors.primary : AppColors.borderStrong,
                      width: 2.0,
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 24),

            // Custom Tactile Keypad
            _buildKeypad(rel),

            const SizedBox(height: 8),

            // Forgot PIN? Ask partner or Set New PIN
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    VibrationService.light();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ResetVaultPinScreen()),
                    );
                  },
                  child: Text(
                    'Forgot PIN? Reset',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text('•', style: AppTextStyles.caption.copyWith(color: AppColors.borderStrong)),
                TextButton(
                  onPressed: () {
                    VibrationService.light();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CreateVaultPinScreen(relId: rel?.id)),
                    );
                  },
                  child: Text(
                    'Set New PIN',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.partner,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildKeypad(RelationshipModel? rel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Row(children: [_numKey('1', rel), const SizedBox(width: 12), _numKey('2', rel), const SizedBox(width: 12), _numKey('3', rel)]),
          const SizedBox(height: 10),
          Row(children: [_numKey('4', rel), const SizedBox(width: 12), _numKey('5', rel), const SizedBox(width: 12), _numKey('6', rel)]),
          const SizedBox(height: 10),
          Row(children: [_numKey('7', rel), const SizedBox(width: 12), _numKey('8', rel), const SizedBox(width: 12), _numKey('9', rel)]),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _handleBiometricUnlock,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: const Icon(Icons.fingerprint_rounded, color: AppColors.primary, size: 24),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _numKey('0', rel),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _onBackspace,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: const Icon(Icons.backspace_outlined, color: AppColors.ink, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _numKey(String text, RelationshipModel? rel) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _onDigit(text, rel),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: AppTextStyles.title1.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }

  // Page 61: Unlocked Photo Vault
  Widget _buildUnlockedGalleryScreen(RelationshipModel? rel) {
    final filters = ['All', 'Us', 'Trips', 'Secrets'];
    final relId = rel?.id ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: relId.isNotEmpty ? _cloudService.streamPrivatePhotos(relId) : Stream.empty(),
          builder: (context, photoSnapshot) {
            final docs = photoSnapshot.data?.docs ?? [];
            final currentFilter = filters[_selectedFilter];
            final filteredDocs = docs.where((doc) {
              if (currentFilter == 'All') return true;
              final data = doc.data() as Map<String, dynamic>;
              return data['category'] == currentFilter;
            }).toList();

            final photoCountStr = '${docs.length} private photo${docs.length == 1 ? '' : 's'}';

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  // Top Bar: Vault + X private photos + Unlocked Pill + Lock button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Vault', style: AppTextStyles.display.copyWith(fontSize: 28)),
                          Text(photoCountStr, style: AppTextStyles.caption),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.mintSoft,
                              borderRadius: BorderRadius.circular(AppRadius.badge),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.lock_open_rounded, color: AppColors.mintText, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  'Unlocked',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.mintText,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {
                              VibrationService.light();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PrivateSpaceSettingsScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.settings_outlined, color: AppColors.ink),
                          ),
                          IconButton(
                            onPressed: lock,
                            icon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Filter Chips: [All] [Us] [Trips] [Secrets]
                  Row(
                    children: List.generate(filters.length, (index) {
                      final isSelected = _selectedFilter == index;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            VibrationService.light();
                            setState(() => _selectedFilter = index);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.card,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.border,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              filters[index],
                              style: AppTextStyles.caption.copyWith(
                                color: isSelected ? Colors.white : AppColors.ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 16),

                  // Quick feature entry cards (Letters & Whispers)
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            VibrationService.light();
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LoveLettersScreen()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.pinkSoft,
                              borderRadius: BorderRadius.circular(AppRadius.card),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.mail_outline_rounded, color: AppColors.primary, size: 20),
                                const SizedBox(width: 8),
                                Text('Love letters', style: AppTextStyles.heading.copyWith(fontSize: 14, color: AppColors.primary)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            VibrationService.light();
                            final activeRel = rel ?? RelationshipModel(
                              uid1: _cloudService.currentUid ?? 'u1',
                              uid2: 'u2',
                              userName1: 'You',
                              userName2: 'Partner',
                              anniversaryDate: DateTime.now(),
                              lastMeetingDate: DateTime.now(),
                              nextMeetingDate: DateTime.now(),
                              distanceKm: 0.0,
                              loveQuote: 'Close, even when you are apart.',
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VoiceWhispersScreen(rel: activeRel),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.partnerSoft,
                              borderRadius: BorderRadius.circular(AppRadius.card),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.mic_none_rounded, color: AppColors.partner, size: 20),
                                const SizedBox(width: 8),
                                Text('Voice whispers', style: AppTextStyles.heading.copyWith(fontSize: 14, color: AppColors.partnerText)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Real 3-Column Photo Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: filteredDocs.length < 8 ? filteredDocs.length + 1 : 9,
                    itemBuilder: (context, index) {
                      if (index == filteredDocs.length || index == 8) {
                        // Add photos tile
                        return GestureDetector(
                          onTap: () {
                            VibrationService.light();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SecretPhotosGalleryScreen(relId: relId),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border, width: 1.5),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_rounded, color: AppColors.primary, size: 24),
                                const SizedBox(height: 4),
                                Text(
                                  'Add photos',
                                  style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w800, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final doc = filteredDocs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final url = data['url'] as String? ?? '';

                      return GestureDetector(
                        onTap: () {
                          VibrationService.light();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SecretPhotosGalleryScreen(relId: relId),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border, width: 1.0),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedNetworkImage(
                                imageUrl: url,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(color: AppColors.pinkSoft),
                                errorWidget: (context, url, error) => Container(
                                  color: AppColors.pinkSoft,
                                  child: const Icon(Icons.broken_image_rounded, color: AppColors.muted),
                                ),
                              ),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.lock_rounded, size: 10, color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Security Guarantee Disclaimer (Page 61)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.partnerSoft,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_outline_rounded, color: AppColors.partner, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Photos are encrypted on your phone. Nobody else can open this space, not even your partner.',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.partnerText,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
