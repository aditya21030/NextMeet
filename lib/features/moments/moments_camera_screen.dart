import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/flat_components.dart';
import 'moment_sent_screen.dart';

/// NextMeet Moments Camera Screen with Photo Frames
/// Strictly following NextMeet Redesign.pdf (Page 27)
class MomentsCameraScreen extends StatefulWidget {
  final String? relId;
  final String partnerName;
  const MomentsCameraScreen({super.key, this.relId, this.partnerName = 'Partner'});

  @override
  State<MomentsCameraScreen> createState() => _MomentsCameraScreenState();
}

class _MomentsCameraScreenState extends State<MomentsCameraScreen> {
  bool _isFlashOn = false;
  bool _isFrontCamera = true;
  int _selectedFrameIndex = 0;
  bool _isCaptured = false;
  final TextEditingController _captionController = TextEditingController();

  final List<Map<String, dynamic>> _frames = [
    {'name': 'Plain', 'icon': Icons.crop_square_rounded},
    {'name': 'Polaroid', 'icon': Icons.photo_size_select_actual_outlined},
    {'name': 'Hearts', 'icon': Icons.favorite_rounded},
    {'name': 'Doodle', 'icon': Icons.draw_rounded},
  ];

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  void _capturePhoto() {
    VibrationService.medium();
    setState(() => _isCaptured = true);
  }

  Future<void> _sendMoment() async {
    VibrationService.heavy();
    final caption = _captionController.text.trim().isNotEmpty
        ? _captionController.text.trim()
        : 'Thinking of you 💕';
    final frame = _frames[_selectedFrameIndex]['name'] as String;

    if (widget.relId != null) {
      try {
        await CloudRelationshipService().sendMoment(widget.relId!, caption, frame);
      } catch (e) {
        debugPrint('Error sending moment: $e');
      }
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MomentSentScreen(
          caption: caption,
          frame: frame,
          partnerName: widget.partnerName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top Controls Bar (Page 27)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (_isCaptured) {
                        setState(() => _isCaptured = false);
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          VibrationService.light();
                          setState(() => _isFlashOn = !_isFlashOn);
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _isFlashOn ? AppColors.butter : Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                            color: _isFlashOn ? AppColors.butterText : Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          VibrationService.light();
                          setState(() => _isFrontCamera = !_isFrontCamera);
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Viewfinder Canvas
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.hero),
                  border: Border.all(
                    color: _selectedFrameIndex == 2 ? AppColors.primary : Colors.white24,
                    width: _selectedFrameIndex == 1 ? 12 : 2,
                  ),
                  color: AppColors.ink.withValues(alpha: 0.9),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Viewfinder preview simulation
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        MascotHeart(
                          color: _isFrontCamera ? MascotColor.pink : MascotColor.violet,
                          size: 90,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isCaptured ? 'Captured!' : 'Smile for ${widget.partnerName}!',
                          style: AppTextStyles.title2.copyWith(color: Colors.white),
                        ),
                      ],
                    ),

                    // Frames Overlay
                    if (_selectedFrameIndex == 2)
                      // Hearts frame
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.primary, width: 4),
                              borderRadius: BorderRadius.circular(AppRadius.card),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('💖', style: TextStyle(fontSize: 22)),
                                  Text('💖', style: TextStyle(fontSize: 22)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Polaroid bottom tab
                    if (_selectedFrameIndex == 1)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                            'NextMeet • Today',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Caption Box if captured
            if (_isCaptured)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: TextField(
                    controller: _captionController,
                    autofocus: true,
                    style: AppTextStyles.body.copyWith(color: AppColors.ink),
                    decoration: const InputDecoration(
                      hintText: 'Add a love note caption...',
                      hintStyle: TextStyle(color: AppColors.muted, fontSize: 14),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              )
            else
              // Frame Selector Carousel (Page 27)
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                  itemCount: _frames.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final isSelected = _selectedFrameIndex == index;
                    final frame = _frames[index];

                    return GestureDetector(
                      onTap: () {
                        VibrationService.light();
                        setState(() => _selectedFrameIndex = index);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white12,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : Colors.white24,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              frame['icon'] as IconData,
                              size: 16,
                              color: isSelected ? Colors.white : Colors.white70,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              frame['name'] as String,
                              style: AppTextStyles.heading.copyWith(
                                fontSize: 13,
                                color: isSelected ? Colors.white : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 20),

            // Bottom Shutter / Send Button Area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              child: _isCaptured
                  ? GestureDetector(
                      onTap: _sendMoment,
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              "Send to ${widget.partnerName}'s Widget",
                              style: AppTextStyles.button.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    )
                  : GestureDetector(
                      onTap: _capturePhoto,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 28),
                        ),
                      ),
                    ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
