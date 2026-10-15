import 'package:flutter/material.dart';
import '../../core/models/relationship_model.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../private_space/lock_screen.dart';
import '../private_space/private_home_screen.dart';

class SanctuaryTab extends StatefulWidget {
  const SanctuaryTab({super.key});

  @override
  State<SanctuaryTab> createState() => _SanctuaryTabState();
}

class _SanctuaryTabState extends State<SanctuaryTab> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  bool _isUnlocked = false;

  void _lock() {
    setState(() => _isUnlocked = false);
  }

  void _unlock() {
    setState(() => _isUnlocked = true);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RelationshipModel?>(
      stream: _cloudService.streamRelationship(),
      builder: (context, snapshot) {
        final rel = snapshot.data;
        // If not paired yet, or no PIN configured, or already unlocked in session:
        if (rel == null || rel.privateSpacePin == null || _isUnlocked) {
          return PrivateHomeScreen(
            onLock: (rel?.privateSpacePin != null) ? _lock : null,
          );
        }

        // Otherwise, show lock screen to verify PIN
        return PrivateSpaceLockScreen(
          onUnlocked: _unlock,
          isTabMode: true,
        );
      },
    );
  }
}
