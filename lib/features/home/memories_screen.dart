import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/models/relationship_model.dart';
import '../../core/models/memory_model.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/flat_components.dart';
import '../../widgets/primary_button.dart';
import 'search_screen.dart';
import 'new_memory_screen.dart';
import 'memory_detail_screen.dart';
import '../moments/moments_screen.dart';

/// NextMeet Memories Masonry Grid Screen
/// Strictly following NextMeet Redesign.pdf (Page 23)
class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({super.key});

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['All', 'Trips', 'Dates', 'Milestones'];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RelationshipModel?>(
      stream: _cloudService.streamRelationship(),
      builder: (context, relSnapshot) {
        final rel = relSnapshot.data;
        final relId = rel?.id;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                // Top Header (Page 23)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Memories', style: AppTextStyles.display.copyWith(fontSize: 28)),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              VibrationService.light();
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const MomentsScreen()),
                              );
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.butterSoft,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.butter, width: 1.5),
                              ),
                              child: const Icon(Icons.photo_camera_rounded, color: AppColors.butterText, size: 20),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              VibrationService.light();
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SearchScreen()),
                              );
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.border, width: 1.5),
                              ),
                              child: const Icon(Icons.search_rounded, color: AppColors.ink, size: 20),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              VibrationService.light();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NewMemoryScreen(relId: relId),
                                ),
                              );
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Filter Pills Row (Page 23)
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

                // Real Masonry Grid View from Cloud Stream
                Expanded(
                  child: relId == null
                      ? _buildEmptyState(relId)
                      : StreamBuilder<List<MemoryModel>>(
                          stream: _cloudService.streamMemories(relId),
                          builder: (context, memSnapshot) {
                            if (memSnapshot.connectionState == ConnectionState.waiting &&
                                !memSnapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(color: AppColors.primary),
                              );
                            }

                            final memories = memSnapshot.data ?? [];
                            final currentFilter = _filters[_selectedFilterIndex];
                            final filtered = memories.where((m) {
                              if (currentFilter == 'All') return true;
                              if (currentFilter == 'Trips') {
                                return m.location.toLowerCase().contains('trip') ||
                                    m.caption.toLowerCase().contains('trip') ||
                                    m.location.toLowerCase().contains('beach') ||
                                    m.location.toLowerCase().contains('flight') ||
                                    m.moodEmoji == '✈️' ||
                                    m.moodEmoji == 'Adventure';
                              }
                              if (currentFilter == 'Dates') {
                                return m.caption.toLowerCase().contains('date') ||
                                    m.caption.toLowerCase().contains('dinner') ||
                                    m.caption.toLowerCase().contains('coffee');
                              }
                              if (currentFilter == 'Milestones') {
                                return m.caption.toLowerCase().contains('anniversary') ||
                                    m.caption.toLowerCase().contains('days') ||
                                    m.caption.toLowerCase().contains('milestone');
                              }
                              return true;
                            }).toList();

                            if (filtered.isEmpty) {
                              return _buildEmptyState(relId);
                            }

                            return _buildMasonryGrid(filtered);
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String? relId) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const MascotHeart(color: MascotColor.pink, size: 72),
            const SizedBox(height: 16),
            Text(
              'No memories yet',
              style: AppTextStyles.title2.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              'Capture your dates, photos, and milestones together to cherish forever.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(color: AppColors.muted, fontSize: 14),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              text: '+ Add Memory',
              height: 44,
              onPressed: () {
                VibrationService.light();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NewMemoryScreen(relId: relId),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMasonryGrid(List<MemoryModel> memories) {
    final leftCol = <MemoryModel>[];
    final rightCol = <MemoryModel>[];

    for (var i = 0; i < memories.length; i++) {
      if (i.isEven) {
        leftCol.add(memories[i]);
      } else {
        rightCol.add(memories[i]);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: leftCol.map((m) => _memoryCard(m)).toList(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: rightCol.map((m) => _memoryCard(m)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _memoryCard(MemoryModel memory) {
    final dateStr = DateFormat('d MMM').format(memory.date);
    final emotionLabel = memory.moodEmoji ?? 'Happy';
    final hasImage = memory.imageUrl.isNotEmpty;

    return GestureDetector(
      onTap: () {
        VibrationService.light();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MemoryDetailScreen(
              memory: memory,
              title: memory.caption.isNotEmpty ? memory.caption : 'Special Moment',
              date: DateFormat('d MMM yyyy').format(memory.date),
              location: memory.location.isNotEmpty ? memory.location : 'Together',
              imageUrl: hasImage ? memory.imageUrl : null,
              emotion: emotionLabel,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photo or Color Card
            if (hasImage)
              CachedNetworkImage(
                imageUrl: memory.imageUrl,
                height: 150,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 150,
                  color: AppColors.pinkSoft,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 120,
                  color: AppColors.pinkSoft,
                  child: const Center(
                    child: Icon(Icons.broken_image_rounded, color: AppColors.muted),
                  ),
                ),
              )
            else
              Container(
                height: 110,
                color: AppColors.pinkSoft,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.favorite_rounded,
                        color: AppColors.primary,
                        size: 32,
                      ),
                      if (memory.location.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          memory.location,
                          style: AppTextStyles.caption.copyWith(color: AppColors.ink, fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dateStr,
                        style: AppTextStyles.caption.copyWith(color: AppColors.muted, fontSize: 11),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.pinkSoft,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          emotionLabel,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    memory.caption.isNotEmpty ? memory.caption : 'Romantic Memory',
                    style: AppTextStyles.heading.copyWith(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
