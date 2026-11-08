import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';

/// NextMeet Help & Feedback Screen
/// Strictly following NextMeet Redesign.pdf (Page 74)
class HelpFeedbackScreen extends StatefulWidget {
  const HelpFeedbackScreen({super.key});

  @override
  State<HelpFeedbackScreen> createState() => _HelpFeedbackScreenState();
}

class _HelpFeedbackScreenState extends State<HelpFeedbackScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedRating = 5;

  final List<Map<String, String>> _faqs = [
    {
      'question': 'How does Heartbeat Sync work?',
      'answer':
          'When you touch and hold the heart on your screen, your partner\'s phone vibrates with the exact same synchronized rhythmic pulse, creating an intimate tactile presence across any distance.',
    },
    {
      'question': 'Is the Sanctum Vault encrypted?',
      'answer':
          'Yes, all photos in the Sanctum Vault are encrypted and accessible only with your 4-digit PIN or biometric fingerprint. Your partner cannot view your personal vault without your permission.',
    },
    {
      'question': 'How do I add home screen widgets?',
      'answer':
          'Go to your phone\'s home screen, press and hold an empty space, tap "Widgets", search for "NextMeet", and choose from the Distance, Heartbeat, Countdown, or Daily Moments photo widgets.',
    },
    {
      'question': 'How can I reconnect if we unpair?',
      'answer':
          'Either partner can generate a fresh 6-digit invite code from the Onboarding or Partner Connection screen, which the other partner enters to link hearts immediately.',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _submitRating() {
    VibrationService.success();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thank you for rating NextMeet 5 stars! ❤️✨'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filteredFaqs = query.isEmpty
        ? _faqs
        : _faqs.where((faq) {
            return faq['question']!.toLowerCase().contains(query) ||
                faq['answer']!.toLowerCase().contains(query);
          }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            if (mounted) setState(() {});
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                // Top Bar
                Row(
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
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 16, color: AppColors.ink),
                      ),
                    ),
                    Text('Help & Support',
                        style: AppTextStyles.title2.copyWith(fontSize: 18)),
                    const SizedBox(width: 40),
                  ],
                ),

                const SizedBox(height: 20),

                // Search FAQs
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded,
                          color: AppColors.muted, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Search help questions...',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            suffixIcon: query.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.muted),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Rating Review Card (Page 74)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.pinkSoft,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Loving NextMeet?',
                        style: AppTextStyles.title1
                            .copyWith(fontSize: 18, color: AppColors.primary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your review helps more couples stay close together!',
                        style: AppTextStyles.caption.copyWith(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final star = index + 1;
                          final isFilled = star <= _selectedRating;
                          return GestureDetector(
                            onTap: () {
                              VibrationService.light();
                              setState(() => _selectedRating = star);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(
                                isFilled
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: AppColors.butterText,
                                size: 32,
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: _submitRating,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            'Rate on Google Play',
                            style: AppTextStyles.button.copyWith(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // FAQs Accordion
                Text('Frequently Asked Questions',
                    style: AppTextStyles.heading.copyWith(fontSize: 16)),
                const SizedBox(height: 12),

                if (filteredFaqs.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'No matching answers found for "$query".',
                      style: AppTextStyles.body.copyWith(color: AppColors.muted, fontSize: 13),
                    ),
                  )
                else
                  ...filteredFaqs.map((faq) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: ExpansionTile(
                        title: Text(
                          faq['question']!,
                          style: AppTextStyles.title2.copyWith(fontSize: 14),
                        ),
                        iconColor: AppColors.primary,
                        collapsedIconColor: AppColors.ink,
                        tilePadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        childrenPadding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        children: [
                          Text(
                            faq['answer']!,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.muted,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                const SizedBox(height: 20),

                // Direct Contact Button
                GestureDetector(
                  onTap: () {
                    VibrationService.light();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Contact love support at support@nextmeet.app ❤️'),
                      ),
                    );
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.email_outlined,
                            color: AppColors.ink, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Email Support (support@nextmeet.app)',
                            style: AppTextStyles.button
                                .copyWith(color: AppColors.ink, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
