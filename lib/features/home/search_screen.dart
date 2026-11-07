import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/models/memory_model.dart';
import '../../core/models/relationship_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/flat_components.dart';

/// NextMeet Universal Search Screen
/// Strictly following NextMeet Redesign.pdf (Page 21)
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  int _selectedFilterIndex = 0; // 0: All, 1: Memories, 2: Places, 3: Letters
  final List<String> _filters = ['All', 'Memories', 'Places', 'Letters'];

  final List<String> _recentSearches = [
    'Sunset beach',
    'Anniversary',
    'Cafe date',
    'Reunion',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = AuthService().currentUid;
    final query = _searchController.text.trim().toLowerCase();
    final currentFilter = _filters[_selectedFilterIndex];

    return StreamBuilder<RelationshipModel?>(
      stream: _cloudService.streamRelationship(),
      builder: (context, relSnap) {
        final rel = relSnap.data;
        final relId = rel?.id ?? 'default_rel';
        final partnerName = rel?.getPartnerName(currentUid) ?? 'Partner';
        final myCity = rel?.getMyLocation(currentUid) ?? 'Here';
        final partnerCity = rel?.getPartnerLocation(currentUid) ?? 'There';

        return StreamBuilder<List<MemoryModel>>(
          stream: _cloudService.streamMemories(relId),
          builder: (context, memSnap) {
            final realMemories = memSnap.data ?? [];
            final List<Map<String, dynamic>> combinedResults = [];

            // Add real Firestore memories
            for (final m in realMemories) {
              final title = m.caption.isNotEmpty ? m.caption : 'Memory at ${m.location}';
              combinedResults.add({
                'type': 'Memories',
                'title': title,
                'date': DateFormat('MMM d, yyyy').format(m.date),
                'location': m.location.isNotEmpty ? m.location : 'Shared Space',
                'icon': Icons.photo_camera_rounded,
                'color': AppColors.primary,
                'bg': AppColors.pinkSoft,
              });
            }

            // Add dynamic couple items
            if (partnerCity.isNotEmpty) {
              combinedResults.add({
                'type': 'Places',
                'title': '$partnerCity Trip',
                'date': 'Visited with $partnerName',
                'location': partnerCity,
                'icon': Icons.place_rounded,
                'color': AppColors.partner,
                'bg': AppColors.partnerSoft,
              });
            }
            if (myCity.isNotEmpty) {
              combinedResults.add({
                'type': 'Places',
                'title': '$myCity Meetup',
                'date': 'Home city',
                'location': myCity,
                'icon': Icons.place_rounded,
                'color': AppColors.mintText,
                'bg': AppColors.mintSoft,
              });
            }

            combinedResults.add({
              'type': 'Letters',
              'title': 'Anniversary Love Letter',
              'date': 'Saved letter',
              'location': 'From $partnerName',
              'icon': Icons.mail_rounded,
              'color': AppColors.butterText,
              'bg': AppColors.butterSoft,
            });

            final filteredResults = combinedResults.where((item) {
              final matchesFilter = currentFilter == 'All' || item['type'] == currentFilter;
              final matchesQuery = query.isEmpty ||
                  (item['title'] as String).toLowerCase().contains(query) ||
                  (item['location'] as String).toLowerCase().contains(query);
              return matchesFilter && matchesQuery;
            }).toList();

            return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Search Bar Row (Page 21)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.input),
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, color: AppColors.muted, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              style: AppTextStyles.body.copyWith(color: AppColors.ink),
                              decoration: const InputDecoration(
                                hintText: 'Search memories, places, letters...',
                                hintStyle: TextStyle(color: AppColors.muted, fontSize: 14),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              child: const Icon(Icons.cancel_rounded, color: AppColors.muted, size: 18),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.heading.copyWith(fontSize: 15, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Horizontal Filters Row (Page 21)
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
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _filters[index],
                          style: AppTextStyles.heading.copyWith(
                            fontSize: 13,
                            color: isSelected ? Colors.white : AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Main Content Area
            Expanded(
              child: query.isEmpty && _selectedFilterIndex == 0
                  ? _buildRecentSearches()
                  : _buildResultsList(filteredResults),
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

  Widget _buildRecentSearches() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent searches', style: AppTextStyles.heading.copyWith(fontSize: 15)),
            GestureDetector(
              onTap: () {
                VibrationService.light();
                setState(() => _recentSearches.clear());
              },
              child: Text(
                'Clear',
                style: AppTextStyles.caption.copyWith(color: AppColors.muted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _recentSearches.map((tag) {
            return GestureDetector(
              onTap: () {
                VibrationService.light();
                _searchController.text = tag;
                setState(() {});
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.history_rounded, size: 14, color: AppColors.muted),
                    const SizedBox(width: 6),
                    Text(tag, style: AppTextStyles.caption.copyWith(color: AppColors.ink)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildResultsList(List<Map<String, dynamic>> results) {
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const MascotHeart(color: MascotColor.pink, size: 60),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: AppTextStyles.title2.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 6),
            Text(
              'Try searching with a different keyword',
              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page, vertical: 8),
      itemCount: results.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = results[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item['bg'] as Color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item['icon'] as IconData,
                  color: item['color'] as Color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] as String,
                      style: AppTextStyles.heading.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item['type']} • ${item['date']} • ${item['location']}',
                      style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.muted, size: 14),
            ],
          ),
        );
      },
    );
  }
}
