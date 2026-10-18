import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/auth_service.dart';
import 'home_screen.dart';
import 'memories_screen.dart';
import 'sanctuary_tab.dart';
import '../profile/profile_screen.dart';
import '../auth/login_screen.dart';
import 'dart:async';
import '../../core/models/relationship_model.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/in_app_update_service.dart';

class MainNavigationScreen extends StatefulWidget {
  final bool initialSynced;
  const MainNavigationScreen({super.key, this.initialSynced = true});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  late StreamSubscription<AppUser?> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = AuthService().authStateChanges.listen((user) {
      if (user == null && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        InAppUpdateService().checkForUpdateSilently(context: context);
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  final GlobalKey<SanctuaryTabState> _sanctuaryKey = GlobalKey<SanctuaryTabState>();
  final CloudRelationshipService _cloudService = CloudRelationshipService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RelationshipModel?>(
      stream: _cloudService.streamRelationship(),
      builder: (context, snapshot) {
        final isPaired = snapshot.hasData && snapshot.data?.uid2 != null;

        return PopScope(
          canPop: _selectedIndex == 0,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (_selectedIndex == 2) {
              _sanctuaryKey.currentState?.lock();
              setState(() => _selectedIndex = 0);
            } else if (_selectedIndex != 0) {
              setState(() => _selectedIndex = 0);
            }
          },
          child: Scaffold(
            body: IndexedStack(
              index: _selectedIndex,
              children: [
                HomeScreen(initialSynced: widget.initialSynced),
                const MemoriesScreen(),
                _selectedIndex == 2
                    ? SanctuaryTab(
                        key: _sanctuaryKey,
                        onExit: () {
                          if (mounted) setState(() => _selectedIndex = 0);
                        },
                      )
                    : const SizedBox.shrink(),
                const ProfileScreen(),
              ],
            ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
              margin: const EdgeInsets.fromLTRB(AppSpacing.m, 0, AppSpacing.m, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.xxl),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                    spreadRadius: -4,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.xxl),
                  child: BottomNavigationBar(
                    currentIndex: _selectedIndex,
                    onTap: (index) {
                      VibrationService.light();
                      setState(() => _selectedIndex = index);
                    },
                    type: BottomNavigationBarType.fixed,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    showSelectedLabels: true,
                    showUnselectedLabels: true,
                    selectedItemColor: AppColors.primary,
                    unselectedItemColor: AppColors.textMuted,
                    selectedLabelStyle: const TextStyle(
                      fontSize: 10, 
                      fontWeight: FontWeight.w900, 
                      letterSpacing: 0.5,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 10, 
                      fontWeight: FontWeight.w500, 
                    ),
                    items: [
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.favorite_outline_rounded),
                        activeIcon: Icon(Icons.favorite_rounded),
                        label: 'US',
                      ),
                      BottomNavigationBarItem(
                        icon: Badge(
                          isLabelVisible: !isPaired,
                          backgroundColor: Colors.transparent,
                          label: const Icon(Icons.lock_rounded, size: 10, color: AppColors.textMuted),
                          child: const Icon(Icons.photo_library_outlined),
                        ),
                        activeIcon: const Icon(Icons.photo_library_rounded),
                        label: 'MEMORIES',
                      ),
                      BottomNavigationBarItem(
                        icon: Badge(
                          isLabelVisible: !isPaired,
                          backgroundColor: Colors.transparent,
                          label: const Icon(Icons.lock_rounded, size: 10, color: AppColors.textMuted),
                          child: const Icon(Icons.shield_moon_outlined),
                        ),
                        activeIcon: const Icon(Icons.shield_moon_rounded),
                        label: 'SANCTUARY',
                      ),
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.person_outline_rounded),
                        activeIcon: Icon(Icons.person_rounded),
                        label: 'PROFILE',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
  }
}
