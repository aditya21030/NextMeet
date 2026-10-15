import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:math';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/glass_card.dart';

class DateIdea {
  final String title;
  final String description;
  final IconData icon;
  final String category;
  final Color color;

  DateIdea(this.title, this.description, this.icon, this.category, this.color);
}

class DateDiscoveryScreen extends StatefulWidget {
  const DateDiscoveryScreen({super.key});

  @override
  State<DateDiscoveryScreen> createState() => _DateDiscoveryScreenState();
}

class _DateDiscoveryScreenState extends State<DateDiscoveryScreen> {
  final List<DateIdea> _ideas = [
    DateIdea('Starlight Picnic', 'Pack some snacks and head to a quiet spot to watch the gems in the sky.', Icons.star_rounded, 'Outdoor', Colors.indigo),
    DateIdea('Virtual Museum', 'Take an online tour of the Louvre or the British Museum together.', Icons.museum_rounded, 'Virtual', Colors.brown),
    DateIdea('Mystery Recipe', 'Both order the same secret ingredients and try to cook them over video call.', Icons.restaurant_rounded, 'Virtual', Colors.orange),
    DateIdea('Playlist Exchange', 'Create a 10-song playlist that describes your week and listen together.', Icons.music_note_rounded, 'Chill', Colors.purple),
    DateIdea('Local Hike', 'Find a trail you\'ve never visited and explore it while sharing photos.', Icons.terrain_rounded, 'Active', Colors.green),
    DateIdea('Lego Build', 'Get the same small Lego set and see who finishes first on camera.', Icons.extension_rounded, 'Fun', Colors.red),
    DateIdea('Gratitude List', 'Write down 5 things you love about each other and read them out loud.', Icons.favorite_rounded, 'Deep', Colors.pink),
  ];

  DateIdea? _featuredIdea;

  @override
  void initState() {
    super.initState();
    _featuredIdea = _ideas[Random().nextInt(_ideas.length)];
  }

  void _shuffle() {
    VibrationService.medium();
    setState(() {
      _featuredIdea = _ideas[Random().nextInt(_ideas.length)];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
        ),
        title: Text('Date Discovery 🔍', style: AppTextStyles.h3),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInDown(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Inspiration for you two ✨', style: AppTextStyles.h2),
                  const SizedBox(height: 4),
                  Text('Never run out of ways to connect.', style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Featured Card
            FadeInUp(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_featuredIdea!.color, _featuredIdea!.color.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.xxl),
                  boxShadow: [
                    BoxShadow(color: _featuredIdea!.color.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                      child: Icon(_featuredIdea!.icon, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 24),
                    Text('"${_featuredIdea!.title}"', style: AppTextStyles.h2.copyWith(color: Colors.white, fontSize: 24)),
                    const SizedBox(height: 12),
                    Text(
                      _featuredIdea!.description, 
                      style: AppTextStyles.bodyM.copyWith(color: Colors.white.withValues(alpha: 0.9), height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _shuffle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _featuredIdea!.color,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
                      ),
                      child: const Text('GIVE ME ANOTHER', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            Text('Quick Categories', style: AppTextStyles.h3),
            const SizedBox(height: 16),
            _buildCategoryRow('Cloud Picnic', 'Outdoor', Icons.cloud_outlined, Colors.blue),
            _buildCategoryRow('Chef Challenge', 'Virtual', Icons.fastfood_outlined, Colors.orange),
            _buildCategoryRow('Movie Marathon', 'Chill', Icons.movie_filter_outlined, Colors.purple),
            _buildCategoryRow('Adventure Hunt', 'Active', Icons.explore_outlined, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRow(String title, String tag, IconData icon, Color color) {
    return FadeInUp(
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyM.copyWith(fontWeight: FontWeight.bold)),
                  Text(tag, style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary, fontSize: 10)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.divider),
          ],
        ),
      ),
    );
  }
}
