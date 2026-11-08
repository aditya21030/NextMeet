import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/models/relationship_model.dart';
import '../../widgets/flat_components.dart';
import '../../widgets/primary_button.dart';

/// NextMeet Secret Photos Gallery Screen
/// Strictly following NextMeet Redesign.pdf (Page 61)
class SecretPhotosGalleryScreen extends StatefulWidget {
  final String? relId;
  const SecretPhotosGalleryScreen({super.key, this.relId});

  @override
  State<SecretPhotosGalleryScreen> createState() =>
      _SecretPhotosGalleryScreenState();
}

class _SecretPhotosGalleryScreenState extends State<SecretPhotosGalleryScreen> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  final ImagePicker _picker = ImagePicker();
  int _selectedFilter = 0;
  final List<String> _filters = ['All', 'Us', 'Trips', 'Secrets'];
  bool _isUploading = false;

  Future<void> _pickAndUploadPhoto(String relId) async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;

      VibrationService.medium();
      setState(() => _isUploading = true);

      final cat = _filters[_selectedFilter] == 'All' ? 'Us' : _filters[_selectedFilter];
      await _cloudService.uploadPrivatePhotoFile(
        relId,
        File(picked.path),
        category: cat,
      );

      if (!mounted) return;
      VibrationService.success();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Encrypted and secured in Vault! 🔒✨'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload photo: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _openPhotoViewer(String relId, QueryDocumentSnapshot doc) {
    VibrationService.light();
    final data = doc.data() as Map<String, dynamic>;
    final url = data['url'] as String? ?? '';
    final category = data['category'] as String? ?? 'Us';
    final sizeBytes = (data['sizeBytes'] as num?)?.toInt() ?? 0;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.hero),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Encrypted Memory',
                          style: AppTextStyles.title2.copyWith(fontSize: 16)),
                      Text('$category • Secured with Vault PIN',
                          style: AppTextStyles.caption),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: AppColors.ink),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 280,
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.pinkSoft,
                      child: const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.pinkSoft,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image_rounded, color: AppColors.muted, size: 40),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        VibrationService.success();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Photo secured in private storage! 🔒✨')),
                        );
                      },
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.pinkSoft,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock_rounded, color: AppColors.primary, size: 18),
                            const SizedBox(width: 6),
                            Text('Encrypted', style: AppTextStyles.button.copyWith(color: AppColors.primary, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () async {
                      VibrationService.medium();
                      Navigator.pop(context);
                      try {
                        await _cloudService.deletePrivatePhoto(relId, doc.id, url, sizeBytes);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Photo deleted from Vault.')),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to delete: $e')),
                        );
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RelationshipModel?>(
      stream: _cloudService.streamRelationship(),
      builder: (context, relSnapshot) {
        final rel = relSnapshot.data;
        final relId = widget.relId ?? rel?.id;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                // Top Header (Page 61)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
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
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Secret Photos', style: AppTextStyles.title2.copyWith(fontSize: 18)),
                              Text('End-to-end private', style: AppTextStyles.caption.copyWith(fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                      if (_isUploading)
                        const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
                        )
                      else if (relId != null)
                        GestureDetector(
                          onTap: () => _pickAndUploadPhoto(relId),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.add_a_photo_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Filter Chips Row
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                    itemCount: _filters.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final isSelected = _selectedFilter == index;
                      return GestureDetector(
                        onTap: () {
                          VibrationService.light();
                          setState(() => _selectedFilter = index);
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

                const SizedBox(height: 14),

                // Real Photos Grid from Firestore Stream
                Expanded(
                  child: relId == null
                      ? _buildEmptyState(relId)
                      : StreamBuilder<QuerySnapshot>(
                          stream: _cloudService.streamPrivatePhotos(relId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting &&
                                !snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(color: AppColors.primary),
                              );
                            }

                            final docs = snapshot.data?.docs ?? [];
                            final currentFilter = _filters[_selectedFilter];
                            final filteredDocs = docs.where((doc) {
                              if (currentFilter == 'All') return true;
                              final data = doc.data() as Map<String, dynamic>;
                              return data['category'] == currentFilter;
                            }).toList();

                            if (filteredDocs.isEmpty) {
                              return _buildEmptyState(relId);
                            }

                            return RefreshIndicator(
                              color: AppColors.primary,
                              onRefresh: () async {
                                if (mounted) setState(() {});
                              },
                              child: GridView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.page,
                                  vertical: 8,
                                ),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 1.0,
                              ),
                              itemCount: filteredDocs.length,
                              itemBuilder: (context, index) {
                                final doc = filteredDocs[index];
                                final data = doc.data() as Map<String, dynamic>;
                                final url = data['url'] as String? ?? '';

                                return GestureDetector(
                                  onTap: () => _openPhotoViewer(relId, doc),
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
                                          placeholder: (context, url) => Container(
                                            color: AppColors.pinkSoft,
                                            child: const Center(
                                              child: SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                          ),
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
                          );
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
              'No secret photos yet',
              style: AppTextStyles.title2.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              'Photos uploaded here are locked behind your private PIN and never shown on your home feed.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(color: AppColors.muted, fontSize: 14),
            ),
            const SizedBox(height: 20),
            if (relId != null)
              PrimaryButton(
                text: '+ Upload Secret Photo',
                height: 44,
                onPressed: () => _pickAndUploadPhoto(relId),
              ),
          ],
        ),
      ),
    );
  }
}
