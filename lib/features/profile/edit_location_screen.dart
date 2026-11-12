import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/models/relationship_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/location_search_service.dart';
import '../../core/services/vibration_service.dart';
import '../../core/cities.dart';
import '../../widgets/primary_button.dart';

/// NextMeet Location & Distance Settings Screen
/// Allows couples to search cities, auto-detect GPS, and update real-time location.
class EditLocationScreen extends StatefulWidget {
  final RelationshipModel? relationship;
  final String relationshipId;

  const EditLocationScreen({
    super.key,
    this.relationship,
    required this.relationshipId,
  });

  @override
  State<EditLocationScreen> createState() => _EditLocationScreenState();
}

class _EditLocationScreenState extends State<EditLocationScreen> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  final LocationSearchService _searchService = LocationSearchService();
  late TextEditingController _searchController;
  Timer? _searchTimer;
  List<LocationResult> _searchResults = [];
  bool _isSearching = false;
  bool _isDetectingGps = false;
  bool _isSaving = false;

  String _currentCity = '';
  double? _selectedLat;
  double? _selectedLng;

  @override
  void initState() {
    super.initState();
    final currentUid = AuthService().currentUid;
    _currentCity = widget.relationship?.getMyLocation(currentUid) ?? '';
    _selectedLat = widget.relationship?.getMyLat(currentUid);
    _selectedLng = widget.relationship?.getMyLng(currentUid);

    _searchController = TextEditingController(text: _currentCity);
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_searchTimer?.isActive ?? false) _searchTimer!.cancel();

    final trimmed = query.trim();
    if (trimmed.length < 3) {
      if (_searchResults.isNotEmpty) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
      return;
    }

    setState(() => _isSearching = true);
    _searchTimer = Timer(const Duration(milliseconds: 400), () async {
      final results = await _searchService.search(trimmed);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    });
  }

  Future<void> _detectGps() async {
    VibrationService.medium();
    setState(() => _isDetectingGps = true);

    final res = await LocationSearchService.getCurrentLocationWithCoords();
    if (!mounted) return;
    setState(() => _isDetectingGps = false);

    if (res != null) {
      VibrationService.success();
      final city = res['city'] as String;
      final lat = res['lat'] as double;
      final lng = res['lng'] as double;

      setState(() {
        _currentCity = city;
        _selectedLat = lat;
        _selectedLng = lng;
        _searchController.text = city;
        _searchResults = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Detected location: $city 📍'),
          backgroundColor: AppColors.primary,
        ),
      );
    } else {
      VibrationService.error();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not detect GPS location. Please check location permissions.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _selectLocation(LocationResult result) {
    VibrationService.light();
    final firstPart = result.name.split(',').first.trim();
    final displayCity = firstPart.isNotEmpty ? firstPart : result.name;

    setState(() {
      _currentCity = displayCity;
      _selectedLat = result.lat;
      _selectedLng = result.lng;
      _searchController.text = displayCity;
      _searchResults = [];
    });
  }

  Future<void> _saveLocation() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    VibrationService.heavy();

    final cityName = _searchController.text.trim();
    if (cityName.isEmpty) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or enter a city name.')),
      );
      return;
    }

    try {
      double? lat = _selectedLat;
      double? lng = _selectedLng;

      if (lat == null || lng == null) {
        final clean = cityName.toLowerCase().trim();
        final primary = clean.split(',').first.trim();
        for (final c in CityData.majorCities) {
          final cName = c.name.toLowerCase();
          if (primary == cName ||
              clean.contains(cName) ||
              (primary.length >= 3 && cName.startsWith(primary))) {
            lat = c.lat;
            lng = c.lng;
            break;
          }
        }
      }

      if (lat == null || lng == null) {
        try {
          final results = await _searchService.search(cityName);
          if (results.isNotEmpty && results.first.hasValidCoordinates) {
            lat = results.first.lat;
            lng = results.first.lng;
          }
        } catch (_) {}
      }

      if (widget.relationshipId.isEmpty || widget.relationshipId == 'default_rel' || widget.relationship == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please pair with your partner before saving your location.')),
        );
        return;
      }

      await _cloudService
          .updateMyStatus(
            widget.relationshipId,
            widget.relationship!,
            city: cityName,
            lat: lat,
            lng: lng,
          )
          .timeout(const Duration(seconds: 8));

      if (!mounted) return;
      VibrationService.success();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location updated to "$cityName"! 📍✨'),
          backgroundColor: AppColors.mintText,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      VibrationService.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving location: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  double? _calculateEstimatedDistance() {
    final currentUid = AuthService().currentUid;
    final pLat = widget.relationship?.getPartnerLat(currentUid);
    final pLng = widget.relationship?.getPartnerLng(currentUid);

    if (_selectedLat != null && _selectedLng != null && pLat != null && pLng != null) {
      if ((_selectedLat == 0.0 && _selectedLng == 0.0) || (pLat == 0.0 && pLng == 0.0)) return null;
      return CityData.calculateDistance(_selectedLat!, _selectedLng!, pLat, pLng);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = AuthService().currentUid;
    final partnerName = widget.relationship?.getPartnerName(currentUid) ?? 'Partner';
    final partnerCity = widget.relationship?.getPartnerLocation(currentUid) ?? '';
    final estimatedDist = _calculateEstimatedDistance();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.ink),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Edit Location',
                      style: AppTextStyles.title2.copyWith(fontSize: 18),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: _isSaving ? null : _saveLocation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text('Save', style: AppTextStyles.button.copyWith(fontSize: 14, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Scrollable Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Current Status Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.pinkSoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('CURRENT LOCATION', style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.muted)),
                                const SizedBox(height: 2),
                                Text(
                                  _currentCity.isNotEmpty ? _currentCity : 'Not configured yet',
                                  style: AppTextStyles.heading.copyWith(fontSize: 15),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_selectedLat != null && _selectedLng != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_selectedLat!.toStringAsFixed(3)}°, ${_selectedLng!.toStringAsFixed(3)}°',
                                    style: AppTextStyles.caption.copyWith(color: AppColors.muted, fontSize: 11),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Quick GPS Action Button
                    GestureDetector(
                      onTap: _isDetectingGps ? null : _detectGps,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.mintSoft,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: AppColors.mint, width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isDetectingGps)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(color: AppColors.mintText, strokeWidth: 2),
                              )
                            else
                              const Icon(Icons.my_location_rounded, color: AppColors.mintText, size: 20),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _isDetectingGps ? 'Fetching GPS coordinates...' : 'Auto-detect Location with GPS',
                                style: AppTextStyles.button.copyWith(color: AppColors.mintText, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // City Search Header
                    Text('Search City or Region', style: AppTextStyles.heading.copyWith(fontSize: 16)),
                    const SizedBox(height: 8),

                    // Search Input
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, color: AppColors.muted, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: AppTextStyles.body,
                              decoration: const InputDecoration(
                                hintText: 'e.g. Mumbai, Paris, Tokyo, New York',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 14),
                              ),
                              onChanged: _onSearchChanged,
                            ),
                          ),
                          if (_isSearching)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                            )
                          else if (_searchController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _searchResults = []);
                              },
                              child: const Icon(Icons.close_rounded, color: AppColors.muted, size: 18),
                            ),
                        ],
                      ),
                    ),

                    // Search Results List (Constrained Height with Scroll)
                    if (_searchResults.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 220),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
                          itemBuilder: (context, index) {
                            final res = _searchResults[index];
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.place_rounded, color: AppColors.primary, size: 20),
                              title: Text(
                                res.name,
                                style: AppTextStyles.body.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => _selectLocation(res),
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Distance Preview Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.partnerSoft,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: AppColors.partnerLight, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.share_location_rounded, color: AppColors.partner, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Partner Distance Calculation',
                                  style: AppTextStyles.heading.copyWith(fontSize: 14, color: AppColors.partnerText),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            partnerCity.isNotEmpty
                                ? '$partnerName is in $partnerCity'
                                : '$partnerName hasn\'t set a city yet',
                            style: AppTextStyles.caption.copyWith(color: AppColors.partnerText.withValues(alpha: 0.9)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          if (estimatedDist != null)
                            Text(
                              'Estimated distance: ${estimatedDist.round()} km apart',
                              style: AppTextStyles.heading.copyWith(fontSize: 16, color: AppColors.primary),
                            )
                          else
                            Text(
                              'Distance will update automatically when you tap Save.',
                              style: AppTextStyles.caption.copyWith(color: AppColors.muted, fontSize: 11),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Save Button
                    PrimaryButton(
                      text: 'Save Location 📍',
                      isLoading: _isSaving,
                      onPressed: _saveLocation,
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
