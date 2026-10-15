import 'dart:io';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/models/relationship_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../profile/nextmeet_plus_screen.dart';
import '../../core/services/image_compression_service.dart';

class SecretPhotosScreen extends StatefulWidget {
  const SecretPhotosScreen({super.key});

  @override
  State<SecretPhotosScreen> createState() => _SecretPhotosScreenState();
}

class _SecretPhotosScreenState extends State<SecretPhotosScreen> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  bool _isUploading = false;

  bool _isRecalculating = false;

  Future<void> _checkAndRepairsStorage(String relId, RelationshipModel rel, List<QueryDocumentSnapshot> docs) async {
    if (_isRecalculating) return;
    int calculatedSize = 0;
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      calculatedSize += (data['sizeBytes'] as int?) ?? 0;
    }
    
    // Only update if there is a mismatch (for old users before byte tracking was added)
    if ((rel.privateSpaceStorageBytes - calculatedSize).abs() > 1024) {
      _isRecalculating = true;
      try {
        await FirebaseFirestore.instance.collection('relationships').doc(relId).update({
          'privateSpaceStorageBytes': calculatedSize,
        });
      } catch (e) {
        // ignore
      } finally {
        _isRecalculating = false;
      }
    }
  }

  Future<void> _showStorageLimitDialog(RelationshipModel rel) {
    final bool isPlus = rel.isPlus;
    VibrationService.error();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Row(
          children: [
            const Icon(Icons.storage_rounded, color: Colors.redAccent),
            const SizedBox(width: 12),
            Text(isPlus ? 'Storage Full 🛑' : 'Vault Full 🛑', style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isPlus 
                ? 'Your premium 150MB vault is full. Please delete some old photos to make room for new memories.'
                : 'Your private vault has reached its 20MB limit. Upgrade to NextMeet+ for 150MB of storage!',
              style: AppTextStyles.bodyM,
            ),
            if (!isPlus) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Unlock 150MB storage and more with NextMeet+',
                        style: AppTextStyles.bodyS.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('LATER', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          if (!isPlus)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => NextMeetPlusScreen(relId: rel.id!)));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('GO PRO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          else
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OKAY', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Future<void> _uploadPhoto(RelationshipModel rel) async {
    final relId = rel.id!;
    final double usedMb = rel.privateSpaceStorageBytes / (1024 * 1024);
    final double limitMb = rel.isPlus ? 150.0 : 20.0;
    
    if (usedMb >= limitMb) {
      _showStorageLimitDialog(rel);
      return;
    }

    VibrationService.medium();
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery, 
      maxWidth: 1280,   // Reasonable resolution
      maxHeight: 1280,
      imageQuality: 50, // Good compression
    );
    
    if (image == null) return;

    setState(() => _isUploading = true);
    try {
      final rawFile = File(image.path);
      // Compress photo to WebP format to save 90%+ vault storage
      final file = await ImageCompressionService.compressToWebp(rawFile);
      final int sizeBytes = await file.length();
      
      // Final check with actual compressed file size
      if ((rel.privateSpaceStorageBytes + sizeBytes) > (limitMb * 1024 * 1024)) {
        _showStorageLimitDialog(rel);
        return;
      }

      final fileName = 'private_${DateTime.now().millisecondsSinceEpoch}.webp';
      final storageRef = _storage.ref().child('relationships/$relId/private_photos/$fileName');
      
      await storageRef.putFile(
        file,
        SettableMetadata(contentType: 'image/webp'),
      );
      final downloadUrl = await storageRef.getDownloadURL();
      
      await _cloudService.addPrivatePhoto(relId, downloadUrl, sizeBytes);
      VibrationService.success();
    } catch (e) {
      print('Upload Error: $e');
      if (mounted) {
        String msg = 'Failed to upload photo ❌';
        if (e.toString().contains('storage')) {
          _showStorageLimitDialog(rel);
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deletePhoto(String relId, String photoId, String url, int sizeBytes) async {
    VibrationService.medium();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo?'),
        content: const Text('This will permanently remove this photo from your Private Space.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('DELETE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _cloudService.deletePrivatePhoto(relId, photoId, url, sizeBytes);
        VibrationService.success();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete photo ❌')));
      }
    }
  }

  Future<void> _downloadImage(String url) async {
    try {
      // 1. Check Permissions
      var status = await Permission.storage.status;
      if (Platform.isAndroid) {
        // For Android 13+, we might need specialized permissions, but Permission.storage often works or gal handles it.
        // Let's use Gal's own permission check if possible, or just request storage.
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
      }

      if (status.isPermanentlyDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Storage permission is required to save photos. Please enable it in settings.'),
              action: SnackBarAction(label: 'SETTINGS', onPressed: () => openAppSettings()),
            ),
          );
        }
        return;
      }

      VibrationService.medium();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Starting download... ⏳'), duration: Duration(seconds: 1)));
      }

      // 2. Download the file to a temp location
      final response = await http.get(Uri.parse(url));
      final bytes = response.bodyBytes;

      final tempDir = await getTemporaryDirectory();
      final path = '${tempDir.path}/nextmeet_download_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File(path);
      await file.writeAsBytes(bytes);

      // 3. Save to Gallery using Gal
      await Gal.putImage(path);
      
      // 4. Cleanup
      await file.delete();

      VibrationService.success();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo saved to gallery! ✅')));
      }
    } catch (e) {
      print('Download Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save photo ❌')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RelationshipModel?>(
      stream: _cloudService.streamRelationship(),
      builder: (context, relSnapshot) {
        final relId = relSnapshot.data?.id;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            leading: IconButton(
              onPressed: () => Navigator.pop(context), 
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 18),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Secret Photos', style: AppTextStyles.h3),
                const SizedBox(width: 8),
                const Icon(Icons.lock_rounded, size: 14, color: Colors.orangeAccent),
              ],
            ),
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
          ),
          body: relId == null 
            ? Center(child: CircularProgressIndicator())
            : StreamBuilder<QuerySnapshot>(
              stream: _cloudService.streamPrivatePhotos(relId),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                
                // Silently update old users' storage count if needed
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && docs.isNotEmpty) {
                    _checkAndRepairsStorage(relId, relSnapshot.data!, docs);
                  }
                });

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.m, AppSpacing.l, AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeInLeft(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Our Private Vault', style: AppTextStyles.h2),
                            Text('Shared moments visible only to you two.', style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      if (_isUploading)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.l),
                          child: LinearProgressIndicator(backgroundColor: AppColors.primary.withValues(alpha: 0.1), color: AppColors.primary),
                        ),
                      if (docs.isEmpty && !_isUploading)
                        Center(
                          child: Column(
                            children: [
                              const SizedBox(height: 100),
                              Icon(Icons.photo_library_outlined, size: 64, color: AppColors.divider),
                              const SizedBox(height: 16),
                              Text('No secret photos yet. Tap + to add!', style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary)),
                            ],
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 20,
                            crossAxisSpacing: 20,
                            childAspectRatio: 0.6,
                          ),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            return FadeInUp(
                              delay: Duration(milliseconds: index * 50),
                              child: GestureDetector(
                                onTap: () => _showFullScreenImage(data['url']),
                                onLongPress: () => _deletePhoto(relId, doc.id, data['url'], data['sizeBytes'] ?? 0),
                                child: _buildPhotoCard(data['url'], data['timestamp'] as Timestamp?),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 100),
                    ],
                  ),
                );
              },
            ),
          floatingActionButton: relSnapshot.data == null ? null : FloatingActionButton(
            onPressed: () => _uploadPhoto(relSnapshot.data!),
            backgroundColor: AppColors.primary,
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: AppColors.primaryGradient,
                boxShadow: AppColors.buttonShadow,
              ),
              child: const Icon(Icons.add_a_photo_rounded, color: Colors.white, size: 24),
            ),
          ),
        );
      }
    );
  }

  void _showFullScreenImage(String url) {
    VibrationService.light();
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) => Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: url,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.white24)),
                  errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _downloadImage(url),
                    icon: const Icon(Icons.download_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCard(String url, Timestamp? timestamp) {
    String timeStr = 'Just now';
    if (timestamp != null) {
      final date = timestamp.toDate();
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 60) {
        timeStr = '${diff.inMinutes}m ago';
      // ignore: curly_braces_in_flow_control_structures
      } else if (diff.inHours < 24) timeStr = '${diff.inHours}h ago';
      else timeStr = '${date.day}/${date.month}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: AppColors.softShadow,
              color: AppColors.divider.withValues(alpha: 0.1),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    memCacheWidth: 400,
                    placeholder: (context, url) => Container(color: AppColors.divider.withValues(alpha: 0.1)),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),
                ),
                Positioned(
                  top: 12, left: 12,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(6)),
                    child: const Icon(Icons.lock_rounded, size: 10, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(timeStr, style: AppTextStyles.bodyS.copyWith(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
              Text('Private Space', style: AppTextStyles.bodyS.copyWith(fontSize: 8, color: AppColors.primary, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}
