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

class VaultHubScreenState extends State<VaultHubScreen> with WidgetsBindingObserver {
  bool _isUnlocked = false;
  String _enteredPin = '';
  int _selectedFilter = 0; // 0: All, 1: Us, 2: Trips, 3: Secrets
  bool _isVerifying = false;
  String? _errorMessage;

  // First-time PIN setup state (when no PIN exists anywhere)
  int _setupStep = 0; // 0: enter new pin, 1: confirm new pin
  String _firstSetupPin = '';

  String? _cachedLocalPin;
  bool _hasLoadedPrefs = false;

  final CloudRelationshipService _cloudService = CloudRelationshipService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLocalPin();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      lock();
    }
  }

  Future<void> _loadLocalPin() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _cachedLocalPin = prefs.getString('vault_pin');
        _hasLoadedPrefs = true;
      });
    }
  }

  void lock() {
    if (mounted) {
      setState(() {
        _isUnlocked = false;
        _enteredPin = '';
        _setupStep = 0;
        _firstSetupPin = '';
        _errorMessage = null;
        _isVerifying = false;
      });
    }
  }

  bool _isPinConfigured(RelationshipModel? rel) {
    final cloudPin = rel?.privateSpacePin;
    if (cloudPin != null && cloudPin.isNotEmpty) return true;
    if (_cachedLocalPin != null && _cachedLocalPin!.isNotEmpty) return true;
    return false;
  }

  void _onDigit(String d, RelationshipModel? rel, bool isSetupMode) {
    if (_isVerifying) return;
    if (_enteredPin.length < 4) {
      VibrationService.light();
      setState(() {
        _enteredPin += d;
        _errorMessage = null;
      });
      if (_enteredPin.length == 4) {
        if (isSetupMode) {
          _handleSetupStep(rel);
        } else {
          _verifyPin(rel);
        }
      }
    }
  }

  void _onBackspace() {
    if (_isVerifying) return;
    if (_enteredPin.isNotEmpty) {
      VibrationService.light();
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = null;
      });
    } else if (_setupStep == 1) {
      VibrationService.light();
      setState(() {
        _setupStep = 0;
        _enteredPin = _firstSetupPin;
        _errorMessage = null;
      });
    }
  }

  Future<void> _handleSetupStep(RelationshipModel? rel) async {
    if (_setupStep == 0) {
      // Step 1 Complete: Remember first PIN and ask for confirmation
      VibrationService.medium();
      setState(() {
        _firstSetupPin = _enteredPin;
        _enteredPin = '';
        _setupStep = 1;
        _errorMessage = null;
      });
    } else {
      // Step 2 Complete: Verify confirmation
      if (_enteredPin == _firstSetupPin) {
        setState(() => _isVerifying = true);
        final pinToSave = _enteredPin;
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('vault_pin', pinToSave);
          _cachedLocalPin = pinToSave;

          final relId = rel?.id;
          if (relId != null && relId.isNotEmpty) {
            await _cloudService.updatePrivateSpacePin(relId, pinToSave);
          }
        } catch (_) {}

        VibrationService.success();
        if (!mounted) return;
        setState(() {
          _isUnlocked = true;
          _enteredPin = '';
          _setupStep = 0;
          _firstSetupPin = '';
          _isVerifying = false;
          _errorMessage = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vault PIN created successfully! 🔒✨'),
            backgroundColor: AppColors.mintText,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // PINs do not match -> Shake/Error and reset to Step 1
        VibrationService.error();
        setState(() {
          _errorMessage = 'PINs did not match. Please try again.';
          _enteredPin = '';
          _setupStep = 0;
          _firstSetupPin = '';
        });
      }
    }
  }

  Future<void> _verifyPin(RelationshipModel? rel) async {
    setState(() => _isVerifying = true);
    final cloudPin = (rel?.privateSpacePin != null && rel!.privateSpacePin!.isNotEmpty)
        ? rel.privateSpacePin
        : null;
    final localPin = (_cachedLocalPin != null && _cachedLocalPin!.isNotEmpty)
        ? _cachedLocalPin
        : null;

    final activePin = cloudPin ?? localPin;

    // If somehow no PIN is found, fallback to setup
    if (activePin == null || activePin.isEmpty) {
      setState(() {
        _isVerifying = false;
        _enteredPin = '';
        _setupStep = 0;
      });
      return;
    }

    if (_enteredPin == cloudPin || _enteredPin == localPin) {
      // Synchronize missing store so local and cloud never desynchronize
      if (localPin != _enteredPin) {
        _cachedLocalPin = _enteredPin;
        SharedPreferences.getInstance().then((prefs) => prefs.setString('vault_pin', _enteredPin));
      }
      final relId = rel?.id;
      if (relId != null && relId.isNotEmpty && cloudPin != _enteredPin) {
        _cloudService.updatePrivateSpacePin(relId, _enteredPin);
      }

      VibrationService.success();
      if (!mounted) return;
      setState(() {
        _isUnlocked = true;
        _enteredPin = '';
        _isVerifying = false;
        _errorMessage = null;
      });
    } else {
      VibrationService.error();
      if (!mounted) return;
      setState(() {
        _enteredPin = '';
        _isVerifying = false;
        _errorMessage = 'Incorrect PIN. Please try again.';
      });
    }
  }

  Future<void> _handleBiometricUnlock() async {
    VibrationService.light();
    final result = await SecurityService().authenticateWithDetails(
      reason: 'Scan fingerprint to open your private Vault',
      biometricOnly: true,
    );
    if (!mounted) return;
    if (result.success) {
      VibrationService.success();
      setState(() {
        _isUnlocked = true;
        _errorMessage = null;
      });
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
          if (!_hasLoadedPrefs) {
            return const Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }
          final hasPin = _isPinConfigured(rel);
          // If no PIN has been configured, guide through first-time setup
          if (!hasPin) {
            return _buildSetupScreen(rel);
          }
          return _buildLockScreen(rel);
        }
        return _buildUnlockedGalleryScreen(rel);
      },
    );
  }

  // First-Time PIN Setup Screen (Step 1 & Step 2)
  Widget _buildSetupScreen(RelationshipModel? rel) {
    final isConfirm = _setupStep == 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (isConfirm) ...[
                          GestureDetector(
                            onTap: () {
                              VibrationService.light();
                              setState(() {
                                _setupStep = 0;
                                _enteredPin = '';
                                _firstSetupPin = '';
                                _errorMessage = null;
                              });
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppColors.border, width: 1.5),
                              ),
                              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: AppColors.ink),
                            ),
                          ),
                        ],
                        Text('Vault Setup', style: AppTextStyles.display.copyWith(fontSize: 26)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.partnerSoft,
                        borderRadius: BorderRadius.circular(AppRadius.badge),
                      ),
                      child: Text(
                        isConfirm ? 'Step 2 of 2' : 'Step 1 of 2',
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

              // Setup Mascot
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.pinkSoft,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: const Center(
                    child: Icon(Icons.shield_outlined, color: AppColors.primary, size: 44),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                isConfirm ? 'Confirm Your PIN' : 'Create Vault PIN',
                style: AppTextStyles.display.copyWith(fontSize: 24),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  isConfirm
                      ? 'Re-enter your 4-digit PIN to confirm.'
                      : 'Choose a 4-digit PIN to protect your secret photos, letters, and whispers.',
                  style: AppTextStyles.body.copyWith(color: AppColors.muted),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 20),

              // 4 PIN Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _enteredPin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
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

              const SizedBox(height: 12),

              // Error banner if any
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  child: Text(
                    _errorMessage!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                const SizedBox(height: 18),

              // Custom Tactile Keypad (isSetupMode = true)
              _buildKeypad(rel, isSetupMode: true),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // Page 58: Enter PIN Lock Screen
  Widget _buildLockScreen(RelationshipModel? rel) {
    final partnerName = rel?.getDisplayPartnerName(_cloudService.currentUid) ?? 'Partner';
    final isMyResetPending = rel != null &&
        rel.pinResetRequestBy == _cloudService.currentUid &&
        !rel.pinResetApproved;
    final isPartnerResetPending = rel != null &&
        rel.pinResetRequestBy != null &&
        rel.pinResetRequestBy != _cloudService.currentUid &&
        !rel.pinResetApproved;
    final isResetApprovedForMe = rel != null &&
        rel.pinResetRequestBy == _cloudService.currentUid &&
        rel.pinResetApproved;

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

              const SizedBox(height: 20),

              // 4 PIN Dots (Page 58)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _enteredPin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
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

              const SizedBox(height: 10),

              // Error feedback
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  child: Text(
                    _errorMessage!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                const SizedBox(height: 16),

              // Partner Reset Request / Approval Actions
              if (isPartnerResetPending)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 6),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      VibrationService.success();
                      await _cloudService.approvePinReset(rel.id!);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Approved PIN reset for $partnerName! ✨')),
                      );
                    },
                    icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                    label: Text('Approve PIN Reset for $partnerName',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                    ),
                  ),
                )
              else if (isMyResetPending)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Waiting for $partnerName to approve...',
                          style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            VibrationService.light();
                            _cloudService.cancelPinReset(rel.id!);
                          },
                          child: Text(
                            'Cancel',
                            style: AppTextStyles.caption.copyWith(color: AppColors.danger, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (isResetApprovedForMe)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 6),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      VibrationService.light();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CreateVaultPinScreen(relId: rel.id)),
                      );
                    },
                    icon: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 18),
                    label: const Text('Reset Approved! Set New PIN 🔑',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mintText,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                    ),
                  ),
                ),

              // Custom Tactile Keypad (isSetupMode = false)
              _buildKeypad(rel, isSetupMode: false),

              const SizedBox(height: 8),

              // Forgot PIN? Reset (Strict, authenticated reset request)
              TextButton(
                onPressed: () {
                  VibrationService.light();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ResetVaultPinScreen(
                        partnerName: partnerName,
                        relId: rel?.id,
                      ),
                    ),
                  );
                },
                child: Text(
                  'Forgot PIN? Reset with Partner 🔒',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad(RelationshipModel? rel, {required bool isSetupMode}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Row(children: [
            _numKey('1', rel, isSetupMode),
            const SizedBox(width: 12),
            _numKey('2', rel, isSetupMode),
            const SizedBox(width: 12),
            _numKey('3', rel, isSetupMode)
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _numKey('4', rel, isSetupMode),
            const SizedBox(width: 12),
            _numKey('5', rel, isSetupMode),
            const SizedBox(width: 12),
            _numKey('6', rel, isSetupMode)
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _numKey('7', rel, isSetupMode),
            const SizedBox(width: 12),
            _numKey('8', rel, isSetupMode),
            const SizedBox(width: 12),
            _numKey('9', rel, isSetupMode)
          ]),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: isSetupMode
                    ? const SizedBox.shrink()
                    : GestureDetector(
                        behavior: HitTestBehavior.opaque,
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
              _numKey('0', rel, isSetupMode),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
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

  Widget _numKey(String text, RelationshipModel? rel, bool isSetupMode) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onDigit(text, rel, isSetupMode),
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
            if (photoSnapshot.connectionState == ConnectionState.waiting &&
                !photoSnapshot.hasData &&
                relId.isNotEmpty) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }

            final docs = photoSnapshot.data?.docs ?? [];
            final currentFilter = filters[_selectedFilter];
            final filteredDocs = docs.where((doc) {
              if (currentFilter == 'All') return true;
              final data = doc.data() as Map<String, dynamic>;
              return data['category'] == currentFilter;
            }).toList();

            final photoCountStr = '${docs.length} private photo${docs.length == 1 ? '' : 's'}';

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                if (mounted) setState(() {});
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
            ),
          );
          },
        ),
      ),
    );
  }
}
