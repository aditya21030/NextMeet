import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../core/models/relationship_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/cloud_relationship_service.dart';
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
  MascotColor _myColor = MascotColor.pink;
  MascotAccessory _myAccessory = MascotAccessory.partyHat;
  final MascotAccessory _partnerAccessory = MascotAccessory.crown;
  int _selectedThemeIndex = 0;
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

  final List<String> _themes = [
    'Blush Romantic (Default)',
    'Midnight Violet',
    'Mint Garden',
    'Sunset Glow',
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final colorIdx = prefs.getInt('custom_mascot_color') ?? 0;
    final accIdx = prefs.getInt('custom_mascot_accessory') ?? 1;
    final themeIdx = prefs.getInt('custom_theme_index') ?? 0;

    setState(() {
      _myColor = MascotColor.values[colorIdx.clamp(0, MascotColor.values.length - 1)];
      _myAccessory = MascotAccessory.values[accIdx.clamp(0, MascotAccessory.values.length - 1)];
      _selectedThemeIndex = themeIdx.clamp(0, _themes.length - 1);
    });
  }

  Future<void> _saveCustomization(String? relId) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    VibrationService.success();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('custom_mascot_color', _myColor.index);
    await prefs.setInt('custom_mascot_accessory', _myAccessory.index);
    await prefs.setInt('custom_theme_index', _selectedThemeIndex);

    if (relId != null && relId != 'default_rel') {
      try {
        await _cloudService.updateRelationshipDetails(relId, {
          'mascotColor': _myColor.name,
          'mascotAccessory': _myAccessory.name,
          'themeIndex': _selectedThemeIndex,
        });
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

        return Scaffold(
          backgroundColor: AppColors.background,
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
                          'Customize',
                          style: AppTextStyles.title2.copyWith(fontSize: 18),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: _isSaving ? null : () => _saveCustomization(rel?.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
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

                const SizedBox(height: 16),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Live Mascot Preview Card (Page 75)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.hero),
                            border: Border.all(color: AppColors.border, width: 1.5),
                          ),
                          child: Column(
                            children: [
                              Text('LIVE PREVIEW', style: AppTextStyles.label.copyWith(color: AppColors.muted, fontSize: 10)),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Column(
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
                                  const SizedBox(width: 24),
                                  Column(
                                    children: [
                                      MascotHeart(
                                        color: MascotColor.violet,
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
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Mascot Accessory Selector (Page 75)
                        Text('Your Mascot Accessory', style: AppTextStyles.heading.copyWith(fontSize: 15)),
                        const SizedBox(height: 10),
                        Row(
                          children: _accessories.map((acc) {
                            final isSelected = _myAccessory == acc['type'];
                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  VibrationService.light();
                                  setState(() => _myAccessory = acc['type'] as MascotAccessory);
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.pinkSoft : Colors.white,
                                    borderRadius: BorderRadius.circular(AppRadius.card),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : AppColors.border,
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
                                              color: isSelected ? AppColors.primary : AppColors.ink,
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
                        Text('Your Mascot Color', style: AppTextStyles.heading.copyWith(fontSize: 15)),
                        const SizedBox(height: 10),
                        Row(
                          children: _colorChoices.map((choice) {
                            final isSelected = _myColor == choice['color'];
                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  VibrationService.light();
                                  setState(() => _myColor = choice['color'] as MascotColor);
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(AppRadius.card),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : AppColors.border,
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
                                              color: isSelected ? AppColors.primary : AppColors.ink,
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

                        // App Color Themes Section (Page 75)
                        Text('App Theme', style: AppTextStyles.heading.copyWith(fontSize: 15)),
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
                              final name = entry.value;
                              final isSelected = _selectedThemeIndex == idx;

                              return Column(
                                children: [
                                  RadioListTile<int>(
                                    value: idx,
                                    groupValue: _selectedThemeIndex,
                                    activeColor: AppColors.primary,
                                    title: Text(name, style: AppTextStyles.body.copyWith(fontSize: 14)),
                                    onChanged: (v) {
                                      VibrationService.light();
                                      setState(() => _selectedThemeIndex = v ?? 0);
                                    },
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
                          onPressed: () => _saveCustomization(rel?.id),
                        ),

                        const SizedBox(height: 24),
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
  }
}
