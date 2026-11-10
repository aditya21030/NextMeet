import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/flat_components.dart';
import 'auth_service.dart';

/// NextMeet Central Theme & Mascot Customization Service
/// Controls dynamic app theming and couple mascot accessories across the entire app
class ThemeService extends ChangeNotifier {
  static final ThemeService instance = ThemeService._();
  ThemeService._();

  int _themeIndex = 0;
  MascotColor _myMascotColor = MascotColor.pink;
  MascotAccessory _myMascotAccessory = MascotAccessory.none;
  MascotColor _partnerMascotColor = MascotColor.violet;
  MascotAccessory _partnerMascotAccessory = MascotAccessory.none;

  int get themeIndex => _themeIndex;
  MascotColor get myMascotColor => _myMascotColor;
  MascotAccessory get myMascotAccessory => _myMascotAccessory;
  MascotColor get partnerMascotColor => _partnerMascotColor;
  MascotAccessory get partnerMascotAccessory => _partnerMascotAccessory;

  /// Dynamic Primary Theme Color
  Color get primaryColor {
    switch (_themeIndex) {
      case 1:
        return const Color(0xFF7B5CF0); // Midnight Violet
      case 2:
        return const Color(0xFF1F7A4F); // Mint Garden
      case 3:
        return const Color(0xFFE65100); // Sunset Glow
      case 0:
      default:
        return const Color(0xFFD81B6A); // Blush Romantic
    }
  }

  /// Dynamic Canvas / Background Color
  Color get backgroundColor {
    switch (_themeIndex) {
      case 1:
        return const Color(0xFFF7F4FF);
      case 2:
        return const Color(0xFFF0FAF5);
      case 3:
        return const Color(0xFFFFF6EE);
      case 0:
      default:
        return const Color(0xFFFFF4F8);
    }
  }

  /// Dynamic Soft Pill / Card Tint Color
  Color get softColor {
    switch (_themeIndex) {
      case 1:
        return const Color(0xFFEDE4FF);
      case 2:
        return const Color(0xFFE3F6EC);
      case 3:
        return const Color(0xFFFFE0D0);
      case 0:
      default:
        return const Color(0xFFFFE0ED);
    }
  }

  /// Dynamic Partner / Secondary Accent Color
  Color get secondaryColor {
    switch (_themeIndex) {
      case 1:
        return const Color(0xFFD81B6A);
      case 2:
        return const Color(0xFF6FCFA0);
      case 3:
        return const Color(0xFFFF8A6B);
      case 0:
      default:
        return const Color(0xFF7B5CF0);
    }
  }

  /// Initialize from local SharedPreferences on app launch
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _themeIndex = (prefs.getInt('custom_theme_index') ?? 0).clamp(0, 3);

      final myColorIdx = prefs.getInt('custom_mascot_color') ?? MascotColor.pink.index;
      _myMascotColor = MascotColor.values[myColorIdx.clamp(0, MascotColor.values.length - 1)];

      final myAccIdx = prefs.getInt('custom_mascot_accessory') ?? MascotAccessory.none.index;
      _myMascotAccessory = MascotAccessory.values[myAccIdx.clamp(0, MascotAccessory.values.length - 1)];

      final partnerColorIdx = prefs.getInt('partner_mascot_color') ?? MascotColor.violet.index;
      _partnerMascotColor = MascotColor.values[partnerColorIdx.clamp(0, MascotColor.values.length - 1)];

      final partnerAccIdx = prefs.getInt('partner_mascot_accessory') ?? MascotAccessory.none.index;
      _partnerMascotAccessory = MascotAccessory.values[partnerAccIdx.clamp(0, MascotAccessory.values.length - 1)];

      notifyListeners();
    } catch (_) {}
  }

  /// Switch theme immediately with listener notification and local persistence
  void setThemeIndex(int index) {
    final clamped = index.clamp(0, 3);
    if (_themeIndex != clamped) {
      _themeIndex = clamped;
      SharedPreferences.getInstance().then((prefs) {
        prefs.setInt('custom_theme_index', clamped);
      }).catchError((_) {});
      notifyListeners();
    }
  }

  /// Update my mascot live with listener notification and local persistence
  void setMyMascot({MascotColor? color, MascotAccessory? accessory}) {
    bool changed = false;
    if (color != null && color != _myMascotColor) {
      _myMascotColor = color;
      changed = true;
    }
    if (accessory != null && accessory != _myMascotAccessory) {
      _myMascotAccessory = accessory;
      changed = true;
    }
    if (changed) {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setInt('custom_mascot_color', _myMascotColor.index);
        prefs.setInt('custom_mascot_accessory', _myMascotAccessory.index);
      }).catchError((_) {});
      notifyListeners();
    }
  }

  /// Update partner mascot live with listener notification and local persistence
  void setPartnerMascot({MascotColor? color, MascotAccessory? accessory}) {
    bool changed = false;
    if (color != null && color != _partnerMascotColor) {
      _partnerMascotColor = color;
      changed = true;
    }
    if (accessory != null && accessory != _partnerMascotAccessory) {
      _partnerMascotAccessory = accessory;
      changed = true;
    }
    if (changed) {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setInt('partner_mascot_color', _partnerMascotColor.index);
        prefs.setInt('partner_mascot_accessory', _partnerMascotAccessory.index);
      }).catchError((_) {});
      notifyListeners();
    }
  }

  /// Sync live values from shared Firestore relationship document with User 1 / User 2 awareness
  void syncFromRelationshipData(Map<String, dynamic> data, {String? currentUid}) {
    bool changed = false;

    if (data['themeIndex'] is num) {
      final t = (data['themeIndex'] as num).toInt().clamp(0, 3);
      if (t != _themeIndex) {
        _themeIndex = t;
        changed = true;
      }
    }

    final effectiveUid = currentUid ?? AuthService().currentUid;
    final isUser2 = (effectiveUid != null && effectiveUid == data['uid2']);

    final myColorStr = (isUser2
            ? (data['user2MascotColor'] ?? data['partnerMascotColor'])
            : (data['user1MascotColor'] ?? data['mascotColor'])) as String?;

    final myAccStr = (isUser2
            ? (data['user2MascotAccessory'] ?? data['partnerMascotAccessory'])
            : (data['user1MascotAccessory'] ?? data['mascotAccessory'])) as String?;

    final partnerColorStr = (isUser2
            ? (data['user1MascotColor'] ?? data['mascotColor'])
            : (data['user2MascotColor'] ?? data['partnerMascotColor'])) as String?;

    final partnerAccStr = (isUser2
            ? (data['user1MascotAccessory'] ?? data['mascotAccessory'])
            : (data['user2MascotAccessory'] ?? data['partnerMascotAccessory'])) as String?;

    if (myColorStr != null) {
      final c = MascotColor.values.firstWhere(
        (e) => e.name == myColorStr,
        orElse: () => _myMascotColor,
      );
      if (c != _myMascotColor) {
        _myMascotColor = c;
        changed = true;
      }
    }

    if (myAccStr != null) {
      final a = MascotAccessory.values.firstWhere(
        (e) => e.name == myAccStr,
        orElse: () => _myMascotAccessory,
      );
      if (a != _myMascotAccessory) {
        _myMascotAccessory = a;
        changed = true;
      }
    }

    if (partnerColorStr != null) {
      final c = MascotColor.values.firstWhere(
        (e) => e.name == partnerColorStr,
        orElse: () => _partnerMascotColor,
      );
      if (c != _partnerMascotColor) {
        _partnerMascotColor = c;
        changed = true;
      }
    }

    if (partnerAccStr != null) {
      final a = MascotAccessory.values.firstWhere(
        (e) => e.name == partnerAccStr,
        orElse: () => _partnerMascotAccessory,
      );
      if (a != _partnerMascotAccessory) {
        _partnerMascotAccessory = a;
        changed = true;
      }
    }

    if (changed) {
      notifyListeners();
    }
  }

  /// Persist customizations and broadcast changes to all listening widgets
  Future<void> setCustomization({
    required int themeIndex,
    required MascotColor myColor,
    required MascotAccessory myAccessory,
    required MascotColor partnerColor,
    required MascotAccessory partnerAccessory,
  }) async {
    _themeIndex = themeIndex.clamp(0, 3);
    _myMascotColor = myColor;
    _myMascotAccessory = myAccessory;
    _partnerMascotColor = partnerColor;
    _partnerMascotAccessory = partnerAccessory;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('custom_theme_index', _themeIndex);
      await prefs.setInt('custom_mascot_color', _myMascotColor.index);
      await prefs.setInt('custom_mascot_accessory', _myMascotAccessory.index);
      await prefs.setInt('partner_mascot_color', _partnerMascotColor.index);
      await prefs.setInt('partner_mascot_accessory', _partnerMascotAccessory.index);
    } catch (_) {}

    notifyListeners();
  }
}
