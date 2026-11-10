import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/models/relationship_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/theme_service.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/flat_components.dart';
import '../../widgets/primary_button.dart';

/// NextMeet App Customization Screen (Mascot Hats, Colors & Theme)
/// Strictly following NextMeet Redesign.pdf (Page 75)
class AppCustomiseScreen extends StatefulWidget {
  const AppCustomiseScreen({super.key});

  @override
  State<AppCustomiseScreen> createState() => _AppCustomiseScreenState();
}

class _AppCustomiseScreenState extends State<AppCustomiseScreen> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();

  int _customizingTarget = 0; // 0: My Mascot, 1: Partner's Mascot
  late MascotColor _myColor;
  late MascotAccessory _myAccessory;
  late MascotColor _partnerColor;
  late MascotAccessory _partnerAccessory;
  late int _selectedThemeIndex;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _accessories = [
    {'name': 'None', 'type': MascotAccessory.none, 'icon': Icons.block_rounded},
    {'name': 'Party Hat', 'type': MascotAccessory.partyHat, 'emoji': '🥳'},
    {'name': 'Cool Cap', 'type': MascotAccessory.cap, 'emoji': '🧢'},
    {'name': 'Crown', 'type': MascotAccessory.crown, 'emoji': '👑'},
  ];

  final List<Map<String, dynamic>> _colorChoices = [
    {'color': MascotColor.pink, 'name': 'Blush Pink', 'fill': AppColors.you},
    {'color': MascotColor.violet, 'name': 'Imperial Violet', 'fill': AppColors.partnerLight},
    {'color': MascotColor.butter, 'name': 'Golden Butter', 'fill': AppColors.butter},
    {'color': MascotColor.mint, 'name': 'Mint Breeze', 'fill': AppColors.mint},
  ];

  final List<Map<String, dynamic>> _themes = [
    {
      'title': 'Blush Romantic (Default)',
      'description': 'Warm pink & romantic blush hues',
      'primary': const Color(0xFFD81B6A),
      'background': const Color(0xFFFFF4F8),
      'soft': const Color(0xFFFFE0ED),
    },
    {
      'title': 'Midnight Violet',
      'description': 'Deep violet & enchanting moonlight vibes',
      'primary': const Color(0xFF7B5CF0),
      'background': const Color(0xFFF7F4FF),
      'soft': const Color(0xFFEDE4FF),
    },
    {
      'title': 'Mint Garden',
      'description': 'Fresh botanical greens & serene calm',
      'primary': const Color(0xFF1F7A4F),
      'background': const Color(0xFFF0FAF5),
      'soft': const Color(0xFFE3F6EC),
    },
    {
      'title': 'Sunset Glow',
      'description': 'Radiant amber & cozy golden sunset',
      'primary': const Color(0xFFE65100),
      'background': const Color(0xFFFFF6EE),
      'soft': const Color(0xFFFFE0D0),
    },
  ];

  @override
  void initState() {
    super.initState();
    _myColor = ThemeService.instance.myMascotColor;
    _myAccessory = ThemeService.instance.myMascotAccessory;
    _partnerColor = ThemeService.instance.partnerMascotColor;
    _partnerAccessory = ThemeService.instance.partnerMascotAccessory;
    _selectedThemeIndex = ThemeService.instance.themeIndex;
  }

  void _onThemeSelected(int index) {
    VibrationService.light();
    setState(() => _selectedThemeIndex = index);
    ThemeService.instance.setThemeIndex(index);
  }

  void _onAccessorySelected(MascotAccessory accessory) {
    VibrationService.light();
    setState(() {
      if (_customizingTarget == 0) {
        _myAccessory = accessory;
        ThemeService.instance.setMyMascot(accessory: accessory);
      } else {
        _partnerAccessory = accessory;
        ThemeService.instance.setPartnerMascot(accessory: accessory);
      }
    });
  }

  void _onColorSelected(MascotColor color) {
    VibrationService.light();
    setState(() {
      if (_customizingTarget == 0) {
        _myColor = color;
        ThemeService.instance.setMyMascot(color: color);
      } else {
        _partnerColor = color;
        ThemeService.instance.setPartnerMascot(color: color);
      }
    });
  }

  Future<void> _saveCustomization(RelationshipModel? rel) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    VibrationService.success();

    final relId = rel?.id;
    final currentUid = AuthService().currentUid;
    final isUser2 = (currentUid != null && currentUid == rel?.uid2);

    await ThemeService.instance.setCustomization(
      themeIndex: _selectedThemeIndex,
      myColor: _myColor,
      myAccessory: _myAccessory,
      partnerColor: _partnerColor,
      partnerAccessory: _partnerAccessory,
    );

    if (relId != null && relId != 'default_rel') {
      try {
        final updateMap = <String, dynamic>{
          'themeIndex': _selectedThemeIndex,
        };

        if (isUser2) {
          updateMap['user2MascotColor'] = _myColor.name;
          updateMap['user2MascotAccessory'] = _myAccessory.name;
          updateMap['user1MascotColor'] = _partnerColor.name;
          updateMap['user1MascotAccessory'] = _partnerAccessory.name;
          // Backwards compatibility keys
          updateMap['partnerMascotColor'] = _myColor.name;
          updateMap['mascotColor'] = _partnerColor.name;
        } else {
          updateMap['user1MascotColor'] = _myColor.name;
          updateMap['user1MascotAccessory'] = _myAccessory.name;
          updateMap['user2MascotColor'] = _partnerColor.name;
          updateMap['user2MascotAccessory'] = _partnerAccessory.name;
          // Backwards compatibility keys
          updateMap['mascotColor'] = _myColor.name;
          updateMap['partnerMascotColor'] = _partnerColor.name;
        }

        await _cloudService.updateRelationshipDetails(relId, updateMap);
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Customization saved to your couple space! ✨'),
        backgroundColor: AppColors.mintText,
      ),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = AuthService().currentUid;

    return StreamBuilder<RelationshipModel?>(
      stream: _cloudService.streamRelationship(),
      builder: (context, snapshot) {
        final rel = snapshot.data;
        final myName = rel?.getMyName(currentUid) ?? 'You';
        final partnerName = rel?.getPartnerName(currentUid) ?? 'Partner';

        return ListenableBuilder(
          listenable: ThemeService.instance,
          builder: (context, _) {
            final activeColor = _customizingTarget == 0 ? _myColor : _partnerColor;
            final activeAccessory = _customizingTarget == 0 ? _myAccessory : _partnerAccessory;

            return Scaffold(
              backgroundColor: ThemeService.instance.backgroundColor,
              body: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    // Top Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                      child: Row(
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
                                border: Border.all(color: AppColors.border, width: 1.5),
                              ),
                              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.ink),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Customize Space',
                              style: AppTextStyles.title2.copyWith(fontSize: 18),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: _isSaving ? null : () => _saveCustomization(rel),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: ThemeService.instance.primaryColor,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text('Save', style: AppTextStyles.button.copyWith(fontSize: 14, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Scrollable Content
                    Expanded(
                      child: SingleChildScrollView(
                        clipBehavior: Clip.none,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Live Mascot Preview Card (Page 75)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(AppRadius.hero),
                                border: Border.all(color: AppColors.border, width: 1.5),
                              ),
                              child: Column(
                                children: [
                                  Text('LIVE PREVIEW', style: AppTextStyles.label.copyWith(color: AppColors.muted, fontSize: 10)),
                                  const SizedBox(height: 14),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          VibrationService.light();
                                          setState(() => _customizingTarget = 0);
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 150),
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: _customizingTarget == 0
                                                ? ThemeService.instance.softColor.withValues(alpha: 0.6)
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(AppRadius.card),
                                            border: Border.all(
                                              color: _customizingTarget == 0
                                                  ? ThemeService.instance.primaryColor
                                                  : Colors.transparent,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              MascotHeart(
                                                color: _myColor,
                                                size: 72,
                                                leanRight: true,
                                                accessory: _myAccessory,
                                              ),
                                              const SizedBox(height: 8),
                                              SizedBox(
                                                width: 80,
                                                child: Text(
                                                  myName,
                                                  style: AppTextStyles.heading.copyWith(fontSize: 14),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      GestureDetector(
                                        onTap: () {
                                          VibrationService.light();
                                          setState(() => _customizingTarget = 1);
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 150),
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: _customizingTarget == 1
                                                ? ThemeService.instance.softColor.withValues(alpha: 0.6)
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(AppRadius.card),
                                            border: Border.all(
                                              color: _customizingTarget == 1
                                                  ? ThemeService.instance.primaryColor
                                                  : Colors.transparent,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              MascotHeart(
                                                color: _partnerColor,
                                                size: 72,
                                                leanLeft: true,
                                                accessory: _partnerAccessory,
                                              ),
                                              const SizedBox(height: 8),
                                              SizedBox(
                                                width: 80,
                                                child: Text(
                                                  partnerName,
                                                  style: AppTextStyles.heading.copyWith(fontSize: 14),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 18),

                            // Mascot Toggle Selector
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                border: Border.all(color: AppColors.border, width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        VibrationService.light();
                                        setState(() => _customizingTarget = 0);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        decoration: BoxDecoration(
                                          color: _customizingTarget == 0
                                              ? ThemeService.instance.primaryColor
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(AppRadius.pill),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'My Mascot ($myName)',
                                          style: AppTextStyles.button.copyWith(
                                            fontSize: 13,
                                            color: _customizingTarget == 0 ? Colors.white : AppColors.ink,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        VibrationService.light();
                                        setState(() => _customizingTarget = 1);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        decoration: BoxDecoration(
                                          color: _customizingTarget == 1
                                              ? ThemeService.instance.primaryColor
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(AppRadius.pill),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          "Partner's ($partnerName)",
                                          style: AppTextStyles.button.copyWith(
                                            fontSize: 13,
                                            color: _customizingTarget == 1 ? Colors.white : AppColors.ink,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Mascot Accessory Selector
                            Text(
                              _customizingTarget == 0 ? 'Your Mascot Accessory' : "$partnerName's Mascot Accessory",
                              style: AppTextStyles.heading.copyWith(fontSize: 15),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: _accessories.map((acc) {
                                final isSelected = activeAccessory == acc['type'];
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () => _onAccessorySelected(acc['type'] as MascotAccessory),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 3),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isSelected ? ThemeService.instance.softColor : Colors.white,
                                        borderRadius: BorderRadius.circular(AppRadius.card),
                                        border: Border.all(
                                          color: isSelected ? ThemeService.instance.primaryColor : AppColors.border,
                                          width: isSelected ? 2.0 : 1.5,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (acc['emoji'] != null)
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(acc['emoji'] as String, style: const TextStyle(fontSize: 22)),
                                            )
                                          else
                                            const Icon(Icons.block_rounded, color: AppColors.muted, size: 22),
                                          const SizedBox(height: 4),
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 4),
                                              child: Text(
                                                acc['name'] as String,
                                                style: AppTextStyles.caption.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 10,
                                                  color: isSelected ? ThemeService.instance.primaryColor : AppColors.ink,
                                                ),
                                                maxLines: 1,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 20),

                            // Mascot Color Selector
                            Text(
                              _customizingTarget == 0 ? 'Your Mascot Color' : "$partnerName's Mascot Color",
                              style: AppTextStyles.heading.copyWith(fontSize: 15),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: _colorChoices.map((choice) {
                                final isSelected = activeColor == choice['color'];
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () => _onColorSelected(choice['color'] as MascotColor),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 3),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(AppRadius.card),
                                        border: Border.all(
                                          color: isSelected ? ThemeService.instance.primaryColor : AppColors.border,
                                          width: isSelected ? 2.0 : 1.5,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: choice['fill'] as Color,
                                              shape: BoxShape.circle,
                                            ),
                                            child: isSelected
                                                ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                                                : null,
                                          ),
                                          const SizedBox(height: 6),
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 4),
                                              child: Text(
                                                choice['name'] as String,
                                                style: AppTextStyles.caption.copyWith(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: isSelected ? ThemeService.instance.primaryColor : AppColors.ink,
                                                ),
                                                maxLines: 1,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 22),

                            // App Color Themes Section
                            Text('App Theme & Palette', style: AppTextStyles.heading.copyWith(fontSize: 15)),
                            const SizedBox(height: 10),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(AppRadius.card),
                                border: Border.all(color: AppColors.border, width: 1.5),
                              ),
                              child: Column(
                                children: _themes.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final theme = entry.value;
                                  final isSelected = _selectedThemeIndex == idx;

                                  return Column(
                                    children: [
                                      InkWell(
                                        onTap: () => _onThemeSelected(idx),
                                        borderRadius: BorderRadius.circular(AppRadius.card),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 24,
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  color: theme['primary'] as Color,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: isSelected ? AppColors.ink : Colors.transparent,
                                                    width: 2,
                                                  ),
                                                ),
                                                child: isSelected
                                                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                                                    : null,
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      theme['title'] as String,
                                                      style: AppTextStyles.body.copyWith(
                                                        fontSize: 14,
                                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                                        color: isSelected ? ThemeService.instance.primaryColor : AppColors.ink,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      theme['description'] as String,
                                                      style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.muted),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 14,
                                                    height: 14,
                                                    decoration: BoxDecoration(
                                                      color: theme['soft'] as Color,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Container(
                                                    width: 14,
                                                    height: 14,
                                                    decoration: BoxDecoration(
                                                      color: theme['primary'] as Color,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (idx < _themes.length - 1)
                                        const Divider(height: 1, color: AppColors.border),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),

                            const SizedBox(height: 24),

                            PrimaryButton(
                              text: 'Save Customization ✨',
                              isLoading: _isSaving,
                              onPressed: () => _saveCustomization(rel),
                            ),

                            const SizedBox(height: 28),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
