import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/models/relationship_model.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../private_space/lock_screen.dart';
import '../private_space/private_home_screen.dart';

class SanctuaryTab extends StatefulWidget {
  final VoidCallback? onExit;
  const SanctuaryTab({super.key, this.onExit});

  @override
  State<SanctuaryTab> createState() => SanctuaryTabState();
}

class SanctuaryTabState extends State<SanctuaryTab> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  bool _isUnlocked = false;

  void lock() {
    if (mounted) setState(() => _isUnlocked = false);
  }

  void _unlock() {
    if (mounted) setState(() => _isUnlocked = true);
  }

  void _handleExit() {
    lock();
    widget.onExit?.call();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RelationshipModel?>(
      stream: _cloudService.streamRelationship(),
      builder: (context, snapshot) {
        final rel = snapshot.data;
        if (rel == null) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        // If paired and has PIN configured, require unlock unless already unlocked in session:
        if (rel.uid2 != null && rel.privateSpacePin != null && !_isUnlocked) {
          return PrivateSpaceLockScreen(
            rel: rel,
            onUnlocked: _unlock,
            onClose: _handleExit,
            isTabMode: true,
          );
        }

        // If paired and no PIN set yet, show lock screen in setup mode
        if (rel.uid2 != null && rel.privateSpacePin == null && !_isUnlocked) {
          return PrivateSpaceLockScreen(
            rel: rel,
            onUnlocked: _unlock,
            onClose: _handleExit,
            isTabMode: true,
          );
        }

        // Otherwise show unlocked PrivateHomeScreen
        return PrivateHomeScreen(
          rel: rel,
          onLock: lock,
          onClose: _handleExit,
        );
      },
    );
  }
}
