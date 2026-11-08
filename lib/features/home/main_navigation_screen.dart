import 'dart:async';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/models/relationship_model.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/in_app_update_service.dart';
import 'home_screen.dart';
import '../games/games_hub_screen.dart';
import '../plan/plan_hub_screen.dart';
import '../private_space/vault_hub_screen.dart';
import '../profile/me_profile_screen.dart';
import '../auth/login_screen.dart';

/// NextMeet 5-Tab Navigation Shell
/// Strictly following NextMeet Redesign.pdf (Pages 16, 18, 34, 47, 58, 67, 85, 86)
class MainNavigationScreen extends StatefulWidget {
  final bool initialSynced;
  const MainNavigationScreen({super.key, this.initialSynced = true});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  late StreamSubscription<AppUser?> _authSubscription;
  StreamSubscription<Uri?>? _widgetClickSubscription;
  final GlobalKey<VaultHubScreenState> _vaultKey = GlobalKey<VaultHubScreenState>();
  final CloudRelationshipService _cloudService = CloudRelationshipService();

  @override
  void initState() {
    super.initState();
    _checkWidgetLaunch();
    _widgetClickSubscription = HomeWidget.widgetClicked.listen((uri) {
      if (uri != null) _handleWidgetUri(uri);
    });

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

  void _handleWidgetUri(Uri uri) {
    if (!mounted) return;
    final path = uri.path.toLowerCase();
    final host = uri.host.toLowerCase();
    int target = 0;
    if (path.contains('plan') || host == 'plan') {
      target = 2;
    } else if (path.contains('vault') || host == 'vault') {
      target = 3;
    } else if (path.contains('games') || host == 'games') {
      target = 1;
    } else if (path.contains('home') || host == 'home') {
      target = 0;
    }
    if (target != 3) {
      _vaultKey.currentState?.lock();
    }
    setState(() => _selectedIndex = target);
  }

  void _checkWidgetLaunch() {
    HomeWidget.initiallyLaunchedFromHomeWidget().then((uri) {
      if (uri != null && mounted) {
        _handleWidgetUri(uri);
      }
    });
  }

  @override
  void dispose() {
    _widgetClickSubscription?.cancel();
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RelationshipModel?>(
      stream: _cloudService.streamRelationship(),
      builder: (context, snapshot) {
        return PopScope(
          canPop: _selectedIndex == 0,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (_selectedIndex == 3) {
              _vaultKey.currentState?.lock();
              setState(() => _selectedIndex = 0);
            } else if (_selectedIndex != 0) {
              setState(() => _selectedIndex = 0);
            }
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: IndexedStack(
              index: _selectedIndex,
              children: [
                HomeScreen(initialSynced: widget.initialSynced),
                const GamesHubScreen(),
                const PlanHubScreen(),
                VaultHubScreen(key: _vaultKey),
                const MeProfileScreen(),
              ],
            ),
            bottomNavigationBar: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1.5),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _navTab(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
                      _navTab(1, Icons.sports_esports_outlined, Icons.sports_esports_rounded, 'Games'),
                      _navTab(2, Icons.calendar_today_outlined, Icons.calendar_month_rounded, 'Plan'),
                      _navTab(3, Icons.lock_outline_rounded, Icons.lock_rounded, 'Vault'),
                      _navTab(4, Icons.person_outline_rounded, Icons.person_rounded, 'Me'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _navTab(int index, IconData outlineIcon, IconData solidIcon, String label) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        VibrationService.light();
        if (index != 3) {
          _vaultKey.currentState?.lock();
        }
        setState(() => _selectedIndex = index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.pinkSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? solidIcon : outlineIcon,
              color: isSelected ? AppColors.primary : AppColors.muted,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? AppColors.primary : AppColors.muted,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
