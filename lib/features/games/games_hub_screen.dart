import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/models/relationship_model.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/flat_components.dart';

// Game Screens
import 'how_well_do_you_know_me_screen.dart';
import 'tic_tac_toe_screen.dart';
import 'connect_four_screen.dart';
import 'never_have_i_ever_screen.dart';
import 'romantic_wheel_screen.dart';
import 'truth_or_dare_screen.dart';
import 'draw_together_screen.dart';
import 'memory_match_screen.dart';
import 'would_you_rather_screen.dart';
import 'couple_level_screen.dart';
import 'badges_screen.dart';
import 'secret_word_screen.dart';
import 'couple_trivia_screen.dart';
import 'emoji_cipher_screen.dart';
import 'dot_and_boxes_screen.dart';
import 'rock_paper_scissors_screen.dart';
import 'song_association_screen.dart';
import 'two_truths_and_lie_screen.dart';
import 'taste_touch_dare_screen.dart';
import 'bucket_list_matcher_screen.dart';
import 'kiss_marry_kill_screen.dart';
import 'couple_word_search_screen.dart';

/// NextMeet Games Hub Screen
/// Strictly following NextMeet Redesign with 20 Complete Real-Time Couple Games
class GamesHubScreen extends StatefulWidget {
  const GamesHubScreen({super.key});

  @override
  State<GamesHubScreen> createState() => _GamesHubScreenState();
}

class _GamesHubScreenState extends State<GamesHubScreen> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Live 2-Player ⚡',
    'Intimacy & Love 💖',
    'Quick & Playful ⏱️',
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RelationshipModel?>(
      stream: _cloudService.streamRelationship(),
      builder: (context, snapshot) {
        final rel = snapshot.data;
        final relId = rel?.id;
        final myUid = _cloudService.currentUid;
        final myName = rel?.getMyName(myUid) ?? 'You';
        final partnerName = rel?.getPartnerName(myUid) ?? 'Partner';
        final partnerUid = rel?.getPartnerUid(myUid);
        final coupleXp = rel?.coupleXp ?? 1240;
        final coupleLevel = 1 + (coupleXp ~/ 200);

        final allGames = _buildAllGamesList(relId, myName, partnerName, partnerUid);
        final filteredGames = _filterGames(allGames);

        final isPaired = rel != null && rel.status == 'active' && rel.uid2 != null;
        final partnerLastActive = rel?.getPartnerLastActive(myUid);
        final bool isOnline = isPaired &&
            partnerLastActive != null &&
            DateTime.now().difference(partnerLastActive).inMinutes < 5;
        final bool isRecent = isPaired &&
            partnerLastActive != null &&
            DateTime.now().difference(partnerLastActive).inMinutes < 60;

        final Color statusDotColor = !isPaired
            ? AppColors.partner
            : (isOnline ? AppColors.mint : (isRecent ? AppColors.butter : AppColors.primary));
        final String statusTitle = !isPaired
            ? 'Pair with Partner'
            : (isOnline
                ? '$partnerName is online'
                : (isRecent ? '$partnerName active recently' : 'Challenge $partnerName'));
        final String statusSubtitle = !isPaired
            ? 'Connect to play 20 live games together!'
            : (isOnline
                ? 'Ready for a real-time game clash!'
                : (isRecent ? 'Send a game move to their phone!' : 'Play live 2-player or local clash!'));

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: Colors.white,
              onRefresh: () async {
                VibrationService.light();
                if (mounted) setState(() {});
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    // Top Bar: "Games" + Level Pill + XP Badge (Page 47)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Games',
                              style: AppTextStyles.display.copyWith(fontSize: 28),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(AppRadius.badge),
                              ),
                              child: Text(
                                '20 Games',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                VibrationService.light();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CoupleLevelScreen(
                                      coupleLevel: coupleLevel,
                                      coupleXp: coupleXp,
                                      relId: relId,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.partnerSoft,
                                  borderRadius: BorderRadius.circular(AppRadius.badge),
                                ),
                                child: Text(
                                  'Level $coupleLevel',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.partnerText,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                VibrationService.light();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const BadgesScreen()),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.butterSoft,
                                  borderRadius: BorderRadius.circular(AppRadius.badge),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star_rounded, color: AppColors.butterText, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$coupleXp',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.butterText,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Card 1: Partner Waiting Prompt Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const MascotHeart(color: MascotColor.violet, size: 40),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: statusDotColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        statusTitle,
                                        style: AppTextStyles.heading.copyWith(fontSize: 15),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  statusSubtitle,
                                  style: AppTextStyles.caption,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              VibrationService.light();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TicTacToeScreen(
                                    relId: relId,
                                    partnerName: partnerName,
                                    partnerUid: partnerUid,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text(
                                'Play Live',
                                style: AppTextStyles.button.copyWith(fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 14),

                  // Card 2: Daily Challenge Hero Banner (Page 47)
                  Container(
                    constraints: const BoxConstraints(minHeight: 160),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.hero),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -10,
                          bottom: 0,
                          child: const TwoMascotsRow(size: 80, spacing: 10),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.butter,
                                borderRadius: BorderRadius.circular(AppRadius.badge),
                              ),
                              child: Text(
                                'Daily challenge',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.butterText,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Finish each other\'s\nsentences',
                              style: AppTextStyles.title1.copyWith(
                                color: Colors.white,
                                fontSize: 20,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () {
                                VibrationService.light();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HowWellDoYouKnowMeScreen(
                                      relId: relId,
                                      myName: myName,
                                      partnerName: partnerName,
                                      partnerUid: partnerUid,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(AppRadius.pill),
                                ),
                                child: Text(
                                  'Play now',
                                  style: AppTextStyles.button.copyWith(
                                    color: AppColors.primary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Category Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              VibrationService.light();
                              setState(() {
                                _selectedCategory = cat;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : AppColors.card,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.border,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                cat == 'All' ? 'All (20)' : cat,
                                style: AppTextStyles.caption.copyWith(
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Games Grid
                  _buildGamesGrid(filteredGames),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

  List<_GameItem> _filterGames(List<_GameItem> all) {
    if (_selectedCategory == 'All') return all;
    if (_selectedCategory == 'Live 2-Player ⚡') {
      return all.where((g) => g.category == 'live').toList();
    }
    if (_selectedCategory == 'Intimacy & Love 💖') {
      return all.where((g) => g.category == 'intimacy').toList();
    }
    if (_selectedCategory == 'Quick & Playful ⏱️') {
      return all.where((g) => g.category == 'quick').toList();
    }
    return all;
  }

  Widget _buildGamesGrid(List<_GameItem> games) {
    final rows = <Widget>[];
    for (int i = 0; i < games.length; i += 2) {
      final g1 = games[i];
      final g2 = (i + 1 < games.length) ? games[i + 1] : null;

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                child: _gameCard(
                  title: g1.title,
                  badge: g1.badge,
                  color: g1.color,
                  titleColor: g1.titleColor,
                  icon: g1.icon,
                  onTap: g1.onTap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: g2 != null
                    ? _gameCard(
                        title: g2.title,
                        badge: g2.badge,
                        color: g2.color,
                        titleColor: g2.titleColor,
                        icon: g2.icon,
                        onTap: g2.onTap,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  List<_GameItem> _buildAllGamesList(String? relId, String myName, String partnerName, String? partnerUid) {
    return [
      // 1. Tic Tac Toe (Live Cloud Sync)
      _GameItem(
        title: 'Tic-tac-toe',
        badge: 'Live ⚡',
        category: 'live',
        color: AppColors.primary,
        icon: Icons.grid_3x3_rounded,
        onTap: () {
          VibrationService.light();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TicTacToeScreen(relId: relId, partnerName: partnerName, partnerUid: partnerUid),
            ),
          );
        },
      ),

      // 2. Hearts in a Row (Live Cloud Sync)
      _GameItem(
        title: 'Hearts in a Row',
        badge: 'Live 4-in-a-row ⚡',
        category: 'live',
        color: AppColors.partner,
        icon: Icons.view_column_rounded,
        onTap: () {
          VibrationService.light();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConnectFourScreen(relId: relId, partnerName: partnerName, partnerUid: partnerUid),
            ),
          );
        },
      ),

      // 3. Draw Together (Live Cloud Sync)
      _GameItem(
        title: 'Draw\ntogether',
        badge: 'Live Canvas 🎨',
        category: 'live',
        color: AppColors.mint,
        titleColor: AppColors.mintText,
        icon: Icons.brush_outlined,
        onTap: () {
          VibrationService.light();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DrawTogetherScreen(relId: relId),
            ),
          );
        },
      ),

      // 4. Wheel of Dates (Live Cloud Sync)
      _GameItem(
        title: 'Wheel of\nDates',
        badge: 'Spin Live 🎡',
        category: 'live',
        color: AppColors.butter,
        titleColor: AppColors.butterText,
        icon: Icons.pie_chart_outline_rounded,
        onTap: () {
          VibrationService.light();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RomanticWheelScreen(relId: relId, partnerName: partnerName),
            ),
          );
        },
      ),

      // 5. Never Have I Ever (Live Cloud Sync)
      _GameItem(
        title: 'Never Have\nI Ever',
        badge: 'Confessions 🙈',
        category: 'live',
        color: AppColors.mint,
        titleColor: AppColors.mintText,
        icon: Icons.visibility_outlined,
        onTap: () {
          VibrationService.light();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NeverHaveIEverScreen(relId: relId, partnerName: partnerName),
            ),
          );
        },
      ),

      // 6. How Well Do You Know Me?
      _GameItem(
        title: 'How well do\nyou know me?',
        badge: '2 min 💖',
        category: 'intimacy',
        color: AppColors.primary,
        icon: Icons.help_outline_rounded,
        onTap: () {
          VibrationService.light();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HowWellDoYouKnowMeScreen(
                relId: relId,
                myName: myName,
                partnerName: partnerName,
                partnerUid: partnerUid,
              ),
            ),
          );
        },
      ),

      // 7. Truth or Dare
      _GameItem(
        title: 'Truth or dare',
        badge: 'Spicy 🌶️',
        category: 'intimacy',
        color: AppColors.butter,
        titleColor: AppColors.butterText,
        icon: Icons.chat_bubble_outline_rounded,
        onTap: () {
          VibrationService.light();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TruthOrDareScreen(relId: relId, partnerName: partnerName),
            ),
          );
        },
      ),

      // 8. Would You Rather
      _GameItem(
        title: 'Would you\nrather',
        badge: 'Dilemmas 🤔',
        category: 'intimacy',
        color: AppColors.primary,
        icon: Icons.compare_arrows_rounded,
        onTap: () {
          VibrationService.light();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WouldYouRatherScreen(relId: relId, partnerName: partnerName, partnerUid: partnerUid),
            ),
          );
        },
      ),

      // 9. Kiss, Marry, or Pass
      _GameItem(
        title: 'Kiss, Marry,\nor Pass',
        badge: 'Priorities 💍',
        category: 'intimacy',
        color: AppColors.partner,
        icon: Icons.volunteer_activism_rounded,
        onTap: () {
          VibrationService.light();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => KissMarryKillScreen(relId: relId, partnerName: partnerName),
            ),
          );
        },
      ),

      // 10. Two Truths & a Lie
      _GameItem(
        title: 'Two Truths\n& a Lie',
        badge: 'Detective 🕵️',
        category: 'intimacy',
        color: AppColors.butter,
        titleColor: AppColors.butterText,
        icon: Icons.psychology_rounded,
        onTap: () {
          VibrationService.light();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TwoTruthsAndLieScreen(relId: relId, partnerName: partnerName),
            ),
          );
        },
      ),

      // 11. Sensory Dares
      _GameItem(
        title: 'Sensory\nDares',
        badge: 'Tactile 🔥',
        category: 'intimacy',
        color: AppColors.mint,
        titleColor: AppColors.mintText,
        icon: Icons.touch_app_rounded,
        onTap: () {
          VibrationService.light();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TasteTouchDareScreen(relId: relId, partnerName: partnerName),
            ),
          );
        },
      ),

      // 12. Date Night Speed Match
      _GameItem(
        title: 'Date Night\nSpeed Match',
        badge: 'Bucket List 💘',
        category: 'intimacy',
        color: AppColors.primary,
        icon: Icons.favorite_border_rounded,
        onTap: () {
          VibrationService.light();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BucketListMatcherScreen(relId: relId, partnerName: partnerName),
            ),
          );
        },
      ),

      // 13. Romantic Word Search
      _GameItem(
        title: 'Romantic\nWord Search',
        badge: 'Garden 🌸',
        category: 'intimacy',
        color: AppColors.partner,
        icon: Icons.manage_search_rounded,
        onTap: () {
          VibrationService.light();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CoupleWordSearchScreen(relId: relId, partnerName: partnerName),
            ),
          );
        },
      ),

      // 14. Secret Love Word (Wordle)
      _GameItem(
        title: 'Secret Love\nWord',
        badge: 'Wordle 💌',
        category: 'quick',
        color: AppColors.mint,
        titleColor: AppColors.mintText,
        icon: Icons.lock_open_rounded,
        onTap: () {
          VibrationService.light();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SecretWordScreen(relId: relId, partnerName: partnerName),
            ),
          );
        },
      ),

      // 15. Couple Trivia Battle
      _GameItem(
        title: 'Couple Trivia\nBattle',
        badge: '10s Timer ⏱️',
        category: 'quick',
        color: AppColors.butter,
        titleColor: AppColors.butterText,
        icon: Icons.quiz_rounded,
        onTap: () {
          VibrationService.light();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CoupleTriviaScreen(relId: relId, partnerName: partnerName),
            ),
          );
        },
      ),

      // 16. Emoji Cipher
      _GameItem(
        title: 'Emoji\nCipher',
        badge: 'Movies 🍿',
        category: 'quick',
        color: AppColors.primary,
        icon: Icons.theater_comedy_rounded,
        onTap: () {
          VibrationService.light();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EmojiCipherScreen(relId: relId, partnerName: partnerName),
            ),
          );
        },
      ),

      // 17. Dots & Heart Boxes
      _GameItem(
        title: 'Dots & Heart\nBoxes',
        badge: 'Territory 📐',
        category: 'quick',
        color: AppColors.partner,
        icon: Icons.dashboard_customize_rounded,
        onTap: () {
          VibrationService.light();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DotAndBoxesScreen(relId: relId, partnerName: partnerName, partnerUid: partnerUid),
            ),
          );
        },
      ),

      // 18. Rock Paper Kiss
      _GameItem(
        title: 'Rock Paper\nKiss',
        badge: 'Forfeits 💋',
        category: 'quick',
        color: AppColors.butter,
        titleColor: AppColors.butterText,
        icon: Icons.sports_kabaddi_rounded,
        onTap: () {
          VibrationService.light();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RockPaperScissorsScreen(relId: relId, partnerName: partnerName, partnerUid: partnerUid),
            ),
          );
        },
      ),

      // 19. Song Association
      _GameItem(
        title: 'Song\nAssociation',
        badge: 'Sing 15s 🎵',
        category: 'quick',
        color: AppColors.mint,
        titleColor: AppColors.mintText,
        icon: Icons.music_note_rounded,
        onTap: () {
          VibrationService.light();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SongAssociationScreen(relId: relId, partnerName: partnerName),
            ),
          );
        },
      ),

      // 20. Memory Match
      _GameItem(
        title: 'Memory\nmatch',
        badge: 'Co-op 🃏',
        category: 'quick',
        color: AppColors.primary,
        icon: Icons.style_outlined,
        onTap: () {
          VibrationService.light();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MemoryMatchScreen(relId: relId),
            ),
          );
        },
      ),
    ];
  }

  Widget _gameCard({
    required String title,
    required String badge,
    required Color color,
    Color? titleColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppRadius.badge),
                ),
                child: Text(
                  badge,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.title2.copyWith(
                      color: titleColor ?? Colors.white,
                      fontSize: 16,
                      height: 1.2,
                    ),
                  ),
                ),
                Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 28),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GameItem {
  final String title;
  final String badge;
  final String category;
  final Color color;
  final Color? titleColor;
  final IconData icon;
  final VoidCallback onTap;

  const _GameItem({
    required this.title,
    required this.badge,
    required this.category,
    required this.color,
    this.titleColor,
    required this.icon,
    required this.onTap,
  });
}
