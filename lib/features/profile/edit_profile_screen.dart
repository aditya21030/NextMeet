import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../core/models/relationship_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../widgets/app_inputs.dart';
import '../../widgets/primary_button.dart';
import '../../core/services/location_search_service.dart';
import 'dart:async';
import '../../core/services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  final String relationshipId;
  final RelationshipModel relationship;
  final bool isPartner;

  const EditProfileScreen({
    super.key,
    required this.relationshipId,
    required this.relationship,
    required this.isPartner,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _locController;
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  final LocationSearchService _searchService = LocationSearchService();
  bool _isLoading = false;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();
  List<LocationResult> _searchResults = [];
  LocationResult? _selectedResult;
  Timer? _searchTimer;
  
  final TextEditingController _oldPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  bool _obscureOld = true;
  bool _obscureNew = true;

  @override
  void initState() {
    super.initState();
    
    final String currentUid = AuthService().currentUid ?? '';
    
    final String currentName = widget.isPartner 
        ? widget.relationship.getPartnerPetName(currentUid)
        : widget.relationship.getMyRealName(currentUid);
    final String currentLoc = widget.isPartner 
        ? widget.relationship.getPartnerLocation(currentUid)
        : widget.relationship.getMyLocation(currentUid);

    _nameController = TextEditingController(text: currentName);
    _locController = TextEditingController(text: currentLoc);
    
    _locController.addListener(_onLocationChanged);
  }

  void _onLocationChanged() {
    if (_searchTimer?.isActive ?? false) _searchTimer!.cancel();
    
    final query = _locController.text.trim();
    if (query.length < 3) {
      if (_searchResults.isNotEmpty) setState(() => _searchResults = []);
      return;
    }

    _searchTimer = Timer(const Duration(milliseconds: 500), () async {
      final results = await _searchService.search(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locController.removeListener(_onLocationChanged);
    _locController.dispose();
    _oldPassController.dispose();
    _newPassController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 50,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      VibrationService.light();
      setState(() => _imageBytes = bytes);
    }
  }

  void _saveProfile() async {
    setState(() => _isLoading = true);
    VibrationService.medium();

    try {
      String? photoUrl;
      if (_imageBytes != null) {
        photoUrl = await _cloudService.uploadProfilePhoto(widget.relationshipId, _imageBytes!);
      }

      final lat = _selectedResult?.lat;
      final lng = _selectedResult?.lng;

      final String currentUid = AuthService().currentUid ?? '';
      final bool isMe1 = currentUid == widget.relationship.uid1;

      if (widget.isPartner) {
        if (isMe1) {
          await _cloudService.updateProfile(
            widget.relationshipId, 
            nick1: _nameController.text,
          );
        } else {
          await _cloudService.updateProfile(
            widget.relationshipId, 
            nick2: _nameController.text,
          );
        }
      } else {
        if (isMe1) {
          await _cloudService.updateProfile(
            widget.relationshipId, 
            name1: _nameController.text, 
            loc1: _selectedResult?.name ?? _locController.text,
            photo1: photoUrl,
            lat1: lat,
            lng1: lng,
          );
        } else {
          await _cloudService.updateProfile(
            widget.relationshipId, 
            name2: _nameController.text, 
            loc2: _selectedResult?.name ?? _locController.text,
            photo2: photoUrl,
            lat2: lat,
            lng2: lng,
          );
        }

        if (_newPassController.text.isNotEmpty) {
          if (_oldPassController.text.isEmpty) {
            throw 'Please enter your current password to change it.';
          }
          await _cloudService.updateUserPassword(
            _oldPassController.text,
            _newPassController.text,
          );
        }
      }

      if (mounted) {
        VibrationService.success();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully! ✨')),
        );
      }
    } catch (e) {
      if (mounted) {
        VibrationService.error();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentUid = AuthService().currentUid ?? '';
    final String currentPhoto = widget.isPartner 
        ? widget.relationship.getPartnerPhoto(currentUid)
        : widget.relationship.getMyPhoto(currentUid);
    final String targetUid = (widget.isPartner 
        ? widget.relationship.getPartnerUid(currentUid) 
        : currentUid) ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.isPartner ? 'Edit Nickname' : 'Edit My Profile', style: AppTextStyles.h3),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInDown(
              child: Center(
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                        boxShadow: AppColors.premiumShadow,
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        backgroundImage: _imageBytes != null 
                            ? MemoryImage(_imageBytes!) as ImageProvider
                            : currentPhoto.isNotEmpty
                                ? CachedNetworkImageProvider(currentPhoto)
                                : NetworkImage('https://api.dicebear.com/7.x/avataaars/png?seed=$targetUid') as ImageProvider,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: AppColors.buttonShadow,
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            FadeInUp(
              delay: const Duration(milliseconds: 100),
              child: _buildInputSection(widget.isPartner ? 'NICKNAME' : 'NAME', _nameController, widget.isPartner ? Icons.favorite_outline_rounded : Icons.person_outline_rounded),
            ),
            if (!widget.isPartner) ...[
              const SizedBox(height: 24),
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: Column(
                  children: [
                    _buildInputSection('LOCATION', _locController, Icons.location_on_outlined),
                    if (_searchResults.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Material(
                          elevation: 8,
                          shadowColor: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: _searchResults.map((result) => InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedResult = result;
                                    _locController.removeListener(_onLocationChanged);
                                    _locController.text = result.name.split(',').first.trim(); // Just show city name
                                    _locController.addListener(_onLocationChanged);
                                    _searchResults = [];
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 0.5)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                                        child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 16),
                                      ),
                                      const SizedBox(width: 12),
                                      Flexible(
                                        child: Text(
                                          result.name, 
                                          style: AppTextStyles.bodyS.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )).toList(),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Password Section (Only for self)
              FadeInUp(
                delay: const Duration(milliseconds: 250),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SECURITY', 
                      style: AppTextStyles.bodyS.copyWith(
                        fontWeight: FontWeight.w900, 
                        color: AppColors.primary, 
                        letterSpacing: 1.2
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: AppInputs.premiumInputDecoration,
                      child: TextField(
                        controller: _oldPassController,
                        obscureText: _obscureOld,
                        style: AppTextStyles.bodyL.copyWith(fontWeight: FontWeight.bold),
                        decoration: AppInputs.premiumInput(
                          'Current Password',
                          icon: Icons.lock_outline_rounded,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(_obscureOld ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary),
                            onPressed: () => setState(() => _obscureOld = !_obscureOld),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: AppInputs.premiumInputDecoration,
                      child: TextField(
                        controller: _newPassController,
                        obscureText: _obscureNew,
                        style: AppTextStyles.bodyL.copyWith(fontWeight: FontWeight.bold),
                        decoration: AppInputs.premiumInput(
                          'New Password',
                          icon: Icons.lock_rounded,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary),
                            onPressed: () => setState(() => _obscureNew = !_obscureNew),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Leave blank if you don\'t want to change password.',
                      style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: PrimaryButton(
                text: 'SAVE PROFILE',
                isLoading: _isLoading,
                onPressed: _saveProfile,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: AppTextStyles.bodyS.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: AppInputs.premiumInputDecoration,
          child: TextField(
            controller: controller,
            style: AppTextStyles.bodyL.copyWith(fontWeight: FontWeight.bold),
            decoration: AppInputs.premiumInput(
              label == 'NAME' ? 'Full Name' : (label == 'LOCATION' ? 'Current City' : label),
              icon: icon,
            ),
          ),
        ),
      ],
    );
  }
}
