import 'dart:io';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/models/relationship_model.dart';
import '../../core/models/memory_model.dart';
import '../../core/cities.dart';
import '../../widgets/sync_error_widget.dart';
import '../onboarding/setup_couple_screen.dart';
import 'package:share_plus/share_plus.dart';

class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({super.key});

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  bool _isBookView = false;

  void _showAddMomentDialog(String relId, RelationshipModel rel, int currentCount) {
    if (!rel.isPlus && currentCount >= 5) {
      VibrationService.error();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Free limits reached (5/5). Please upgrade to NextMeet+ to add unlimited memories! ✨')),
      );
      return;
    }

    VibrationService.medium();
    String newLocation = '';
    File? selectedImage;
    bool isStory = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
          ),
          padding: EdgeInsets.only(
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            top: AppSpacing.xl,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('Capture a Moment 📸', style: AppTextStyles.h2),
                const SizedBox(height: AppSpacing.m),
                Text('Every bit of your story matters.', style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.xl),
                
                GestureDetector(
                  onTap: () async {
                    final XFile? image = await _picker.pickImage(
                      source: ImageSource.gallery, 
                      maxWidth: 1024,
                      maxHeight: 1024,
                      imageQuality: 50,
                    );
                    if (image != null) {
                      setModalState(() => selectedImage = File(image.path));
                    }
                  },
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 2),
                      image: selectedImage != null 
                          ? DecorationImage(image: FileImage(selectedImage!), fit: BoxFit.cover) 
                          : null,
                    ),
                    child: selectedImage == null ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_rounded, size: 48, color: AppColors.primary),
                        SizedBox(height: 12),
                        Text('Tap to Select Photo', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],
                    ) : null,
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xl),
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text == '') {
                      return const Iterable<String>.empty();
                    }
                    return CityData.majorCities
                        .map((c) => c.name)
                        .where((name) => name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  },
                  onSelected: (String selection) {
                    newLocation = selection;
                  },
                  fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      onChanged: (v) => newLocation = v,
                      decoration: InputDecoration(
                        hintText: 'Select City...',
                        prefixIcon: const Icon(Icons.location_city_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.l),
                
                Theme(
                  data: ThemeData(checkboxTheme: CheckboxThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)))),
                  child: CheckboxListTile(
                    value: isStory,
                    onChanged: (v) => setModalState(() => isStory = v ?? false),
                    title: const Text('Add to Stories ✨', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Highlighted at the top of your memories'),
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xxl),
                
                if (_isUploading)
                  const Center(child: CircularProgressIndicator())
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (selectedImage == null) {
                          VibrationService.error();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select a photo first! 📸')),
                          );
                          return;
                        }

                        setModalState(() => _isUploading = true);
                        try {
                          final finalLocation = newLocation.trim().isEmpty ? 'Our Journey ❤️' : newLocation.trim();
                          await _cloudService.addMemory(relId, selectedImage!, "", finalLocation, isStory: isStory);
                          VibrationService.success();
      // ignore: use_build_context_synchronously
                          if (mounted) Navigator.pop(context);
      // ignore: use_build_context_synchronously
                        } catch (e) {
                           ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to save memory: $e')),
                          );
                        } finally {
                          if (mounted) setState(() => _isUploading = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
                      ),
                      child: const Text('SAVE TO JOURNEY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _viewStory(MemoryModel moment, String relId, RelationshipModel rel) {
    VibrationService.medium();
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => _StoryPage(moment: moment, relId: relId, rel: rel, cloudService: _cloudService),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RelationshipModel?>(
      stream: _cloudService.streamRelationship(),
      builder: (context, relSnapshot) {
        if (relSnapshot.hasError) {
          return Scaffold(
            body: SyncErrorWidget(
              errorMessage: 'Failed to sync relationship data.',
              onRetry: () => setState(() {}),
            ),
          );
        }

        if (relSnapshot.connectionState == ConnectionState.waiting && !relSnapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!relSnapshot.hasData || relSnapshot.data?.id == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              title: Text('Memories', style: AppTextStyles.h3),
              centerTitle: true,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite_outline_rounded, size: 56, color: AppColors.primary),
                    ),
                    const SizedBox(height: 24),
                    Text('No Memories Yet', style: AppTextStyles.h2, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    Text(
                      'Pair with your partner to start creating a shared digital timeline of your moments and milestones.',
                      style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const SetupCoupleScreen()));
                      },
                      icon: const Icon(Icons.favorite_rounded, color: Colors.white, size: 18),
                      label: const Text('Connect with Partner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.m)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        
        final rel = relSnapshot.data!;

        if (rel.uid2 == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              title: Text('Memories', style: AppTextStyles.h3),
              centerTitle: true,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_outline_rounded, size: 56, color: AppColors.primary),
                    ),
                    const SizedBox(height: 24),
                    Text('Unlock Shared Memories ✨', style: AppTextStyles.h2, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    Text(
                      'Unlock shared memories and build your couple timeline as soon as your partner joins your journey!',
                      style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton.icon(
                      onPressed: () {
                        VibrationService.medium();
                        Share.share(AppLinks.getInviteMessage(rel.inviteCode ?? ''));
                      },
                      icon: const Icon(Icons.share_rounded, color: Colors.white, size: 18),
                      label: Text('Share Love Code (${rel.inviteCode ?? ''})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.m)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final relId = rel.id!;

        return StreamBuilder<List<MemoryModel>>(
          stream: _cloudService.streamMemories(relId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: SyncErrorWidget(
                    errorMessage: 'Unable to load moments.',
                    onRetry: () => setState(() {}),
                  ),
                ),
              );
            }
            
            final moments = snapshot.data ?? [];
            final stories = moments.where((m) => m.isStory).toList();
            
            return Scaffold(
              backgroundColor: AppColors.background,
              body: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: AppSpacing.l),
                            if (stories.isNotEmpty) ...[
                              _buildFeaturedMemory(stories[0], relId, rel),
                              const SizedBox(height: AppSpacing.xxl),
                            ],
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('All Moments', style: AppTextStyles.h3),
                                Row(
                                  children: [
                                    if (rel.isPlus) ...[
                                      IconButton(
                                        onPressed: () => setState(() => _isBookView = !_isBookView),
                                        icon: Icon(
                                          _isBookView ? Icons.grid_view_rounded : Icons.auto_stories_rounded, 
                                          color: AppColors.primary
                                        ),
                                        tooltip: _isBookView ? 'Switch to Gallery' : 'Switch to Storybook',
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    _buildCountBadge(moments.length),
                                  ],
                                ),
                              ],
                            ),
                          const SizedBox(height: AppSpacing.l),
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Search city...',
                              prefixIcon: const Icon(Icons.search_rounded),
                              fillColor: AppColors.background,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.m),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.l),
                          if (rel.isPlus)
                            (_isBookView ? _buildStorybookAlbum(moments, relId, rel) : _buildPremiumAlbum(moments, relId, rel))
                          else
                            _buildFreeGrid(moments, relId, rel),
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ),
                ],
              ),
              floatingActionButton: FadeInUp(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 84),
                  child: FloatingActionButton(
                    onPressed: () => _showAddMomentDialog(relId, rel, moments.length),
                    backgroundColor: AppColors.primary,
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: const Icon(Icons.add_a_photo_rounded, color: Colors.white, size: 28),
                  ),
                ),
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildCountBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count',
        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 12),
      ),
    );
  }

  Widget _buildEmptyState(String relId) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 100),
          Icon(Icons.photo_library_outlined, size: 80, color: AppColors.primary.withValues(alpha: 0.1)),
          const SizedBox(height: 24),
          Text('No Memories Yet', style: AppTextStyles.h2),
          const SizedBox(height: 12),
          Text('Your love story is just beginning.', style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildFeaturedMemory(MemoryModel featured, String relId, RelationshipModel rel) {
    return GestureDetector(
      onTap: () => _viewStory(featured, relId, rel),
      child: Container(
        width: double.infinity,
        height: 380,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          boxShadow: AppColors.premiumShadow,
          image: DecorationImage(image: NetworkImage(featured.imageUrl), fit: BoxFit.cover),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.1), Colors.black.withValues(alpha: 0.85)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                child: const Text('LATEST STORY ✨', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 12),
              Text(featured.location, style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 32)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 12, color: Colors.white70),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMM dd, yyyy').format(featured.date).toUpperCase(), 
                        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w800, fontSize: 10),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.circle)),
                    child: const Text('VIEW STORY', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 10)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFreeGrid(List<MemoryModel> moments, String relId, RelationshipModel rel) {
    if (moments.isEmpty) return _buildEmptyState(relId);
    return _buildMomentsGrid(moments, relId, rel);
  }

  Widget _buildPremiumAlbum(List<MemoryModel> moments, String relId, RelationshipModel rel) {
    if (moments.isEmpty) return _buildEmptyState(relId);
    
    final Map<String, List<MemoryModel>> grouped = {};
    for (var m in moments) {
      final key = DateFormat('MMMM yyyy').format(m.date);
      grouped.putIfAbsent(key, () => []).add(m);
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) {
      final dateA = DateFormat('MMMM yyyy').parse(a);
      final dateB = DateFormat('MMMM yyyy').parse(b);
      return dateB.compareTo(dateA);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.8), AppColors.primary]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10)],
          ),
          child: Row(
            children: [
              const Icon(Icons.stars_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NEXTMEET+ ALBUM ✨', style: AppTextStyles.bodyS.copyWith(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                    Text('${moments.length} / ${AppSubscription.plusMaxMemories} Memories Used', style: AppTextStyles.bodyS.copyWith(color: Colors.white.withValues(alpha: 0.8))),
                  ],
                ),
              ),
              if (moments.isNotEmpty)
                IconButton(
                  onPressed: () => _showCinematicReels(moments, relId, rel),
                  icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 32),
                  tooltip: 'Play Cinematic Recap',
                ),
            ],
          ),
        ),

        ...sortedKeys.map((month) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 16, top: 8),
                child: Text(month.toUpperCase(), style: AppTextStyles.bodyS.copyWith(fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: 2)),
              ),
              GridView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 0.75,
                ),
                itemCount: grouped[month]!.length,
                itemBuilder: (context, index) {
                  final moment = grouped[month]![index];
                  return _buildPolaroidCard(moment, relId, rel);
                },
              ),
              const SizedBox(height: 32),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildStorybookAlbum(List<MemoryModel> moments, String relId, RelationshipModel rel) {
    if (moments.isEmpty) return _buildEmptyState(relId);
    
    return SizedBox(
      height: 600,
      child: _ArchiveBookEngine(
        moments: moments, 
        relId: relId, 
        rel: rel, 
        cloudService: _cloudService
      ),
    );
  }

  void _showCinematicReels(List<MemoryModel> moments, String relId, RelationshipModel rel) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Reels',
      barrierColor: Colors.black,
      pageBuilder: (context, _, _) => _CinematicReelsPage(moments: moments),
    );
  }

  Widget _buildPolaroidCard(MemoryModel moment, String relId, RelationshipModel rel) {
    final isPlus = rel.isPlus;
    
    return FadeInUp(
      child: GestureDetector(
        onTap: () => _viewStory(moment, relId, rel),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
          decoration: BoxDecoration(
            color: isPlus ? Colors.white.withValues(alpha: 0.8) : Colors.white,
            borderRadius: BorderRadius.circular(isPlus ? 12 : 4),
            border: isPlus ? Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 1.5) : null,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(isPlus ? 8 : 2),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.network(moment.imageUrl, fit: BoxFit.cover),
                      ),
                      if (isPlus)
                        Positioned(
                          top: 8, right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), shape: BoxShape.circle),
                            child: const Icon(Icons.star_rounded, color: Colors.white, size: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      moment.location.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Inter', 
                        fontSize: 9, 
                        fontWeight: FontWeight.w900, 
                        letterSpacing: 0.5,
                        color: isPlus ? AppColors.primary : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('MMM dd, yyyy').format(moment.date),
                      style: TextStyle(fontSize: 8, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMomentsGrid(List<MemoryModel> moments, String relId, RelationshipModel rel) {
    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: moments.length,
      itemBuilder: (context, index) {
        final moment = moments[index];
        return GestureDetector(
          onTap: () => _viewStory(moment, relId, rel),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: AppColors.softShadow,
              image: DecorationImage(image: NetworkImage(moment.imageUrl), fit: BoxFit.cover),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
                ),
              ),
              padding: const EdgeInsets.all(12),
              alignment: Alignment.bottomLeft,
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      moment.location, 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
      // ignore: unused_element
  }

  Widget _buildReelBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _StoryPage extends StatefulWidget {
  final MemoryModel moment;
  final String relId;
  final RelationshipModel rel;
  final CloudRelationshipService cloudService;

  const _StoryPage({required this.moment, required this.relId, required this.rel, required this.cloudService});

  @override
  State<_StoryPage> createState() => _StoryPageState();
}

class _StoryPageState extends State<_StoryPage> {
  final TextEditingController _editController = TextEditingController();
  bool get _isUser1 => widget.cloudService.currentUid == widget.rel.uid1;

  Future<void> _deleteMoment() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Memory?'),
        content: const Text('Are you sure you want to remove this beautiful moment from your journey?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.cloudService.deleteMemory(widget.relId, widget.moment.id!, widget.moment.imageUrl);
      VibrationService.medium();
      if (mounted) Navigator.pop(context);
    }
  }

  void _showEditCaption() {
    _editController.text = _isUser1 ? (widget.moment.partner1Caption ?? '') : (widget.moment.partner2Caption ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Your Perspective ✍️', style: AppTextStyles.h3),
              const SizedBox(height: 16),
              TextField(
                controller: _editController,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'What were you thinking in this moment?'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_isUser1) {
                      await widget.cloudService.updateMemoryCaptions(widget.relId, widget.moment.id!, p1Caption: _editController.text);
      // ignore: use_build_context_synchronously
                    } else {
                      await widget.cloudService.updateMemoryCaptions(widget.relId, widget.moment.id!, p2Caption: _editController.text);
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('SAVE CAPTION'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: Image.network(widget.moment.imageUrl, fit: BoxFit.cover)),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.4), Colors.transparent, Colors.transparent, Colors.black.withValues(alpha: 0.9)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStoryBadge(DateFormat('MMMM dd, yyyy').format(widget.moment.date).toUpperCase()),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _deleteMoment,
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 32),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  FadeInUp(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.moment.location, style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 36)),
                        const SizedBox(height: 24),
                        const Text('OUR PERSPECTIVES', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                        const SizedBox(height: 12),
                        _buildPerspectiveTile(
                          _isUser1 ? 'YOU SAID' : 'PARTNER SAID', 
                          widget.moment.partner1Caption ?? 'No thoughts yet...', 
                          () { if (_isUser1) _showEditCaption(); }
                        ),
                        const SizedBox(height: 12),
                        _buildPerspectiveTile(
                          !_isUser1 ? 'YOU SAID' : 'PARTNER SAID', 
                          widget.moment.partner2Caption ?? 'No thoughts yet...', 
                          () { if (!_isUser1) _showEditCaption(); }
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.white30)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
    );
  }

  Widget _buildPerspectiveTile(String label, String content, VoidCallback onTap) {
    bool isMine = label.contains('YOU');
    return GestureDetector(
      onTap: isMine ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMine ? Colors.white.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05), 
          borderRadius: BorderRadius.circular(12), 
          border: Border.all(color: isMine ? AppColors.primary.withValues(alpha: 0.3) : Colors.white10)
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: isMine ? AppColors.primary : Colors.white30, fontSize: 8, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.7,
                  child: Text(content, style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.4)),
                ),
              ],
            ),
            const Spacer(),
            if (isMine) const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 18),
          ],
        ),
      ),
    );
  }
}

class _CinematicReelsPage extends StatefulWidget {
  final List<MemoryModel> moments;
  const _CinematicReelsPage({required this.moments});

  @override
  State<_CinematicReelsPage> createState() => _CinematicReelsPageState();
}

class _CinematicReelsPageState extends State<_CinematicReelsPage> {
  int _currentIndex = 0;
  final bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _isPlaying) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % widget.moments.length;
        });
        _startTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final moment = widget.moments[_currentIndex];
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(seconds: 1),
              child: Image.network(
                moment.imageUrl,
                key: ValueKey(moment.id),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.4), Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: List.generate(widget.moments.length, (index) {
                      return Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: index <= _currentIndex ? Colors.white : Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildReelBadge(moment.location.toUpperCase()),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 32),
                      ),
                    ],
                  ),
                  const Spacer(),
                  FadeInUp(
                    key: ValueKey('content_$_currentIndex'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('MMMM yyyy').format(moment.date).toUpperCase(),
                          style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          moment.location,
                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                        if (moment.caption.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              moment.caption,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5, fontStyle: FontStyle.italic),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: Row(
              children: [
                Expanded(child: GestureDetector(onTap: () { setState(() { _currentIndex = (_currentIndex - 1 + widget.moments.length) % widget.moments.length; }); })),
                Expanded(child: GestureDetector(onTap: () { setState(() { _currentIndex = (_currentIndex + 1) % widget.moments.length; }); })),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReelBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.white.withValues(alpha: 0.3))),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
    );
  }
}

class _ArchiveBookEngine extends StatefulWidget {
  final List<MemoryModel> moments;
  final String relId;
  final RelationshipModel rel;
  final CloudRelationshipService cloudService;

  const _ArchiveBookEngine({required this.moments, required this.relId, required this.rel, required this.cloudService});

  @override
  State<_ArchiveBookEngine> createState() => _ArchiveBookEngineState();
}

class _ArchiveBookEngineState extends State<_ArchiveBookEngine> {
  late PageController _pageController;
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _pageController.addListener(() { setState(() { _currentPage = _pageController.page ?? 0; }); });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.moments.length,
      clipBehavior: Clip.none,
      itemBuilder: (context, index) {
      // ignore: deprecated_member_use
        final moment = widget.moments[index];
        double delta = index - _currentPage;
        double rotation = (delta * 0.45).clamp(-0.8, 0.8);
        return Transform(
          transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(rotation)..translate(delta * 15.0, delta.abs() * 40.0, 0),
          alignment: delta > 0 ? Alignment.centerLeft : Alignment.centerRight,
          child: _ArchivePageContent(moment: moment, relId: widget.relId, rel: widget.rel, cloudService: widget.cloudService, isCurrent: delta.abs() < 0.1),
        );
      },
    );
  }
}

class _ArchivePageContent extends StatelessWidget {
  final MemoryModel moment;
  final String relId;
  final RelationshipModel rel;
  final CloudRelationshipService cloudService;
  final bool isCurrent;

  const _ArchivePageContent({required this.moment, required this.relId, required this.rel, required this.cloudService, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 25),
      decoration: BoxDecoration(
        color: const Color(0xFFF4ECD8),
        borderRadius: BorderRadius.circular(2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 25, offset: const Offset(8, 12)), BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 1, spreadRadius: -3, offset: const Offset(-2, 0))],
      ),
      child: Stack(
        children: [
          Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Colors.black.withValues(alpha: 0.08), Colors.transparent, Colors.transparent, Colors.black.withValues(alpha: 0.05)])))),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Stack(alignment: Alignment.center, children: [Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))]), child: ClipRRect(child: Image.network(moment.imageUrl, height: 280, width: double.infinity, fit: BoxFit.cover))), _buildAntiqueCorner(Alignment.topLeft), _buildAntiqueCorner(Alignment.topRight), _buildAntiqueCorner(Alignment.bottomLeft), _buildAntiqueCorner(Alignment.bottomRight)])),
                const SizedBox(height: 36),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      moment.location.toUpperCase(),
                      style: TextStyle(fontFamily: 'serif', fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2.2, color: Colors.brown.shade800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('MMM dd, yyyy').format(moment.date),
                      style: TextStyle(fontFamily: 'serif', fontSize: 12, fontStyle: FontStyle.italic, color: Colors.brown.shade500),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(child: GestureDetector(onTap: () => _showInkJournal(context), child: SizedBox(width: double.infinity, child: Text(moment.caption.isEmpty ? 'Tap to scribe the memory...' : moment.caption, style: const TextStyle(fontFamily: 'GreatVibes', fontSize: 22, height: 1.4, color: Color(0xFF2C3E50)))))),
                const Divider(color: Colors.black12, thickness: 0.8),
                Center(child: Text('Eternal Archive 📜 Signature Series', style: TextStyle(fontSize: 8, color: Colors.brown.withValues(alpha: 0.35), letterSpacing: 1.8, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
        ],
      ),
    );
  }
      // ignore: use_build_context_synchronously

  Widget _buildAntiqueCorner(Alignment alignment) { return Positioned(top: alignment.y == -1 ? 0 : null, bottom: alignment.y == 1 ? 0 : null, left: alignment.x == -1 ? 0 : null, right: alignment.x == 1 ? 0 : null, child: Transform.rotate(angle: (alignment.x * alignment.y) * 0.78, child: Container(width: 24, height: 24, decoration: BoxDecoration(color: Colors.grey.shade400.withValues(alpha: 0.4), border: Border.all(color: Colors.white24, width: 0.5), borderRadius: BorderRadius.circular(1))))); }

  void _showInkJournal(BuildContext context) {
    final controller = TextEditingController(text: moment.caption);
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => Container(decoration: const BoxDecoration(color: Color(0xFFF4ECD8), borderRadius: BorderRadius.vertical(top: Radius.circular(24))), padding: EdgeInsets.only(left: 24, right: 24, top: 28, bottom: MediaQuery.of(context).viewInsets.bottom + 24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Ink & Quill 🖋️', style: TextStyle(fontFamily: 'serif', fontSize: 26, fontWeight: FontWeight.bold, color: Colors.brown)), const SizedBox(height: 18), TextField(controller: controller, maxLines: 7, autofocus: true, style: const TextStyle(fontFamily: 'serif', fontSize: 17, color: Color(0xFF2C3E50), height: 1.5), decoration: const InputDecoration(border: InputBorder.none, hintText: 'Describe this moment poetically...', hintStyle: TextStyle(fontStyle: FontStyle.italic, color: Colors.black26))), const SizedBox(height: 32), SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () async { await cloudService.updateMemoryCaptions(relId, moment.id!, caption: controller.text); Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.brown.shade800, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: const Text('SEAL TO ARCHIVE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5))))])));
  }
}
