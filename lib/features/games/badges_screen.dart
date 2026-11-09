import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/flat_components.dart';

/// NextMeet 12 Romantic Badges & Achievements Screen
/// Strictly following NextMeet Redesign.pdf (Page 56)
class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['All (12)', 'Earned (8)', 'Locked (4)'];

  final List<Map<String, dynamic>> _badges = [
    {
      'title': 'Distance Warrior',
      'emoji': '🌍',
      'desc': 'Navigated over 5,000 km of distance together',
      'earned': true,
      'date': 'Earned Nov 2024',
    },
    {
      'title': 'Night Owl Callers',
      'emoji': '🦉',
      'desc': 'Stayed on video call past 2:00 AM',
      'earned': true,
      'date': 'Earned Dec 2024',
    },
    {
      'title': 'Puzzle Masters',
      'emoji': '🧩',
      'desc': 'Played and won 10 couple games',
      'earned': true,
      'date': 'Earned Jan 2025',
    },
    {
      'title': '1,000 Hearts',
      'emoji': '💓',
      'desc': 'Held heartbeat sync together 50 times',
      'earned': true,
      'date': 'Earned Feb 2025',
    },
    {
      'title': 'Love Letter Laureate',
      'emoji': '💌',
      'desc': 'Exchanged 20 sealed love letters',
      'earned': true,
      'date': 'Earned Mar 2025',
    },
    {
      'title': 'Jetsetters',
      'emoji': '✈️',
      'desc': 'Planned and celebrated 3 reunion trips',
      'earned': true,
      'date': 'Earned Apr 2025',
    },
    {
      'title': 'Secret Keepers',
      'emoji': '🔒',
      'desc': 'Saved 20 encrypted memories in Sanctum Vault',
      'earned': true,
      'date': 'Earned Jun 2025',
    },
    {
      'title': 'Streak Champions',
      'emoji': '🔥',
      'desc': 'Maintained a 40-day continuous streak',
      'earned': true,
      'date': 'Earned Oct 2025',
    },
    {
      'title': '1 Year Together',
      'emoji': '💍',
      'desc': 'Reach 365 days of partnership',
      'earned': false,
      'date': 'Unlocks on Anniversary',
    },
    {
      'title': 'Master Chef',
      'emoji': '🍳',
      'desc': 'Cook 5 recipes together over video call',
      'earned': false,
      'date': '2 of 5 done',
    },
    {
      'title': 'Stargazers',
      'emoji': '🔭',
      'desc': 'Stargaze while on voice call for 1 hour',
      'earned': false,
      'date': 'Locked',
    },
    {
      'title': 'Forever & Always',
      'emoji': '♾️',
      'desc': 'Complete 1,000 days of distance together',
      'earned': false,
      'date': '8 days remaining',
    },
  ];

  void _showBadgeDetail(Map<String, dynamic> badge) {
    VibrationService.light();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.hero)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(badge['emoji'] as String, style: const TextStyle(fontSize: 54)),
              const SizedBox(height: 14),
              Text(badge['title'] as String, style: AppTextStyles.title1.copyWith(fontSize: 22)),
              const SizedBox(height: 8),
              Text(
                badge['desc'] as String,
                style: AppTextStyles.body.copyWith(color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: badge['earned'] == true ? AppColors.mintSoft : AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: badge['earned'] == true ? AppColors.mint : AppColors.border,
                    width: 1,
                  ),
                ),
                child: Text(
                  badge['date'] as String,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w800,
                    color: badge['earned'] == true ? AppColors.mintText : AppColors.muted,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _badges.where((b) {
      if (_selectedFilterIndex == 1) return b['earned'] == true;
      if (_selectedFilterIndex == 2) return b['earned'] == false;
      return true;
    }).toList();

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
                      'Couple Badges',
                      style: AppTextStyles.title2.copyWith(fontSize: 18),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.butterSoft,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: AppColors.butter, width: 1.5),
                    ),
                    child: Text('8/12 Earned', style: AppTextStyles.caption.copyWith(color: AppColors.butterText, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Filter Tabs Row
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                itemCount: _filters.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final isSelected = _selectedFilterIndex == index;
                  return GestureDetector(
                    onTap: () {
                      VibrationService.light();
                      setState(() => _selectedFilterIndex = index);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        _filters[index],
                        style: AppTextStyles.heading.copyWith(
                          fontSize: 13,
                          color: isSelected ? Colors.white : AppColors.ink,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Badges 3x4 Grid (Page 56)
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page, vertical: 4),
                itemCount: filtered.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.85,
                ),
                itemBuilder: (context, index) {
                  final badge = filtered[index];
                  final isEarned = badge['earned'] == true;

                  return GestureDetector(
                    onTap: () => _showBadgeDetail(badge),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isEarned ? Colors.white : AppColors.background,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(
                          color: isEarned ? AppColors.border : AppColors.border.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Opacity(
                            opacity: isEarned ? 1.0 : 0.4,
                            child: Text(badge['emoji'] as String, style: const TextStyle(fontSize: 34)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            badge['title'] as String,
                            style: AppTextStyles.heading.copyWith(
                              fontSize: 11,
                              color: isEarned ? AppColors.ink : AppColors.muted,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
