import 'package:flutter/material.dart';
import 'models/milestone_model.dart';

class AchievementsData {
  static List<Milestone> getMilestones() {
    return [
      // --- STREAKS ---
      _m('streak_3', 'Three\'s a habit', '3-day streak', 'STREAKS', 'Habits are built in threes', Icons.local_fire_department_rounded, Colors.orange, 'streak', 3),
      _m('streak_7', 'One whole week', '7-day streak', 'STREAKS', 'Seven days of showing up for each other', Icons.auto_awesome_rounded, Colors.orangeAccent, 'streak', 7),
      _m('streak_14', 'Fortnight flames', '14-day streak', 'STREAKS', 'Two weeks. The streak is real now', Icons.bolt_rounded, Colors.amber, 'streak', 14),
      _m('streak_21', 'Three week rule', '21-day streak', 'STREAKS', 'They say 21 days makes a habit. You did it', Icons.cyclone_rounded, Colors.blueAccent, 'streak', 21),
      _m('streak_30', 'One full moon', '30-day streak', 'STREAKS', 'A whole month of loving each day', Icons.nightlight_round, Colors.orangeAccent, 'streak', 30),
      _m('streak_45', '45 days devoted', '45-day streak', 'STREAKS', 'Six weeks and still not missing a beat', Icons.favorite_rounded, Colors.pink, 'streak', 45),
      _m('streak_60', 'Two months deep', '60-day streak', 'STREAKS', 'You two are genuinely committed', Icons.fitness_center_rounded, Colors.amberAccent, 'streak', 60),
      _m('streak_75', '75 days of us', '75-day streak', 'STREAKS', 'This isn\'t luck. This is dedication', Icons.local_florist_rounded, Colors.pinkAccent, 'streak', 75),
      _m('streak_90', 'Quarter year', '90-day streak', 'STREAKS', 'Three months. You built something real', Icons.military_tech_rounded, Colors.orange, 'streak', 90),
      _m('streak_100', '100 days of love', '100-day streak', 'STREAKS', 'A century of showing up. Iconic', Icons.favorite_rounded, Colors.red, 'streak', 100),
      _m('streak_150', 'Halfway to six', '150-day streak', 'STREAKS', 'You are unstoppable at this point', Icons.wb_sunny_rounded, Colors.yellow, 'streak', 150),
      _m('streak_180', 'Half a year', '180-day streak', 'STREAKS', 'Six months. That is not a streak, it is a lifestyle', Icons.diamond_rounded, Colors.cyan, 'streak', 180),
      _m('streak_250', '250 days of us', '250-day streak', 'STREAKS', 'A quarter thousand days. Legendary', Icons.star_rounded, Colors.amber, 'streak', 250),
      _m('streak_365', 'One full year', '365-day streak', 'STREAKS', '365 days. A complete year together on NextMeet', Icons.cake_rounded, Colors.orange, 'streak', 365),
      _m('streak_500', '500 days of us', '500-day streak', 'STREAKS', 'Five hundred days. This is your love story', Icons.emoji_events_rounded, Colors.amber, 'streak', 500),
      _m('streak_730', 'Two full years', '730-day streak', 'STREAKS', 'Two years on NextMeet. You are the standard', Icons.favorite_rounded, Colors.pink, 'streak', 730),
      _m('streak_1000', '1000 days', '1000-day streak', 'STREAKS', 'One thousand days. There are no words', Icons.auto_awesome_mosaic_rounded, Colors.blue, 'streak', 1000),

      // --- CONNECTION ---
      _m('hug_1', 'First hug', 'first action', 'CONNECTION', 'The first hug is always the sweetest', Icons.sentiment_satisfied_alt_rounded, Colors.orange, 'virtual_hugs', 1),
      _m('hug_7', 'Hug every day', '7-day hug run', 'CONNECTION', 'Seven hugs in seven days. Feel the warmth', Icons.favorite_rounded, Colors.pink, 'virtual_hugs', 7),
      _m('sync_1', 'In sync', 'first sync', 'CONNECTION', 'Your hearts beat together for the first time', Icons.favorite_border_rounded, Colors.pinkAccent, 'sync_hearts', 1),
      _m('sync_10', 'Heartbeat lovers', '10 syncs', 'CONNECTION', 'Ten times your hearts found each other', Icons.favorite_rounded, Colors.red, 'sync_hearts', 10),
      _m('sync_50', 'Soulmates', '50 syncs', 'CONNECTION', 'Fifty syncs. You are each other\'s rhythm', Icons.auto_awesome_rounded, Colors.pink, 'sync_hearts', 50),
      _m('miss_1', 'Missing you', 'first notif', 'CONNECTION', 'You felt it and you said it. That matters', Icons.sentiment_dissatisfied_rounded, Colors.orange, 'miss_you', 1),
      _m('miss_100', 'Always thinking', '100 notifs', 'CONNECTION', 'A hundred moments of missing and saying so', Icons.cloud_rounded, Colors.blueGrey, 'miss_you', 100),
      _m('quiz_1', 'Tell me everything', 'first quiz', 'CONNECTION', 'Every couple starts with one honest question', Icons.psychology_rounded, Colors.purple, 'quizzes_done', 1),
      _m('quiz_10', 'Quiz obsessed', '10 quizzes', 'CONNECTION', 'Ten quizzes. You are getting to know each other deeply', Icons.track_changes_rounded, Colors.red, 'quizzes_done', 10),
      _m('quiz_50', 'Mind reader', '50 quizzes', 'CONNECTION', 'Fifty quizzes in. You practically finish each other\'s sentences', Icons.auto_fix_high_rounded, Colors.purpleAccent, 'quizzes_done', 50),
      _m('mood_7', 'Open book', '7-day mood', 'CONNECTION', 'Seven days of sharing how you really feel', Icons.sentiment_very_satisfied_rounded, Colors.amber, 'mood_shares', 7),
      _m('mood_30', 'Emotionally open', '30-day mood', 'CONNECTION', 'A month of honesty. That is rare and beautiful', Icons.wb_cloudy_rounded, Colors.blue, 'mood_shares', 30),

      // --- MEMORIES ---
      _m('memory_1', 'First memory', 'first photo', 'MEMORIES', 'Every album starts with a single photo', Icons.camera_alt_rounded, Colors.blueGrey, 'memories', 1),
      _m('memory_10', 'Memory keeper', '10 photos', 'MEMORIES', 'Ten memories worth keeping forever', Icons.collections_rounded, Colors.blue, 'memories', 10),
      _m('memory_50', 'Memory collector', '50 photos', 'MEMORIES', 'Fifty moments you never want to forget', Icons.photo_library_rounded, Colors.teal, 'memories', 50),
      _m('memory_100', 'Story of us', '100 photos', 'MEMORIES', 'A hundred memories. That is a whole love story', Icons.favorite_rounded, Colors.pinkAccent, 'memories', 100),
      _m('milestone_1', 'Timeline started', 'first milestone', 'MEMORIES', 'You marked your first moment. More will follow', Icons.calendar_month_rounded, Colors.blueAccent, 'milestones_done', 1),
      _m('milestone_10', 'Our story', '10 milestones', 'MEMORIES', 'Ten chapters of a love story still being written', Icons.menu_book_rounded, Colors.blue, 'milestones_done', 10),
      _m('quote_7', 'Daily dose', '7-day quote', 'MEMORIES', 'Seven days of love in words', Icons.chat_bubble_rounded, Colors.purpleAccent, 'daily_quotes', 7),
      _m('slideshow_1', 'Movie night', 'first slideshow', 'MEMORIES', 'Your memories. Your soundtrack. Your story', Icons.movie_filter_rounded, Colors.deepPurple, 'slideshows_created', 1),

      // --- TRIPS ---
      _m('date_1', 'Let us do something', 'first date idea', 'TRIPS', 'The first plan is always the most exciting', Icons.event_rounded, Colors.orangeAccent, 'date_ideas', 1),
      _m('trip_1', 'First trip together', 'first trip', 'TRIPS', 'Every adventure starts with a destination', Icons.public_rounded, Colors.blue, 'trips_planned', 1),
      _m('adventure_1', 'Adventure complete', 'trip done', 'TRIPS', 'You planned it. You went. You made it a memory', Icons.check_box_rounded, Colors.green, 'trips_completed', 1),
      _m('explorer_5', 'Explorers', '5 trips', 'TRIPS', 'Five adventures and still hungry for more', Icons.explore_rounded, Colors.orange, 'trips_completed', 5),
      _m('bucket_1', 'Dream big', 'bucket list item', 'TRIPS', 'A dream written down is a dream halfway done', Icons.star_border_rounded, Colors.amber, 'bucket_items', 1),
      _m('bucket_done_1', 'Bucket list hero', 'bucket done', 'TRIPS', 'You dreamed it, planned it, and lived it', Icons.star_rounded, Colors.amberAccent, 'bucket_done', 1),
      _m('packing_1', 'Ready to go', 'packing complete', 'TRIPS', 'Bags packed. Hearts ready', Icons.luggage_rounded, Colors.blueGrey, 'packing_lists', 1),
      _m('plan_vibe', 'Master planner', 'full itinerary', 'TRIPS', 'Every detail planned. Every moment thought of', Icons.map_rounded, Colors.green, 'itineraries_full', 1),

      // --- PRIVATE SPACE ---
      _m('vault_access', 'Our secret place', 'first visit', 'PRIVATE SPACE', 'A space that belongs only to the two of you', Icons.lock_rounded, Colors.pinkAccent, 'private_visits', 1),
      _m('letter_1', 'Love letter', 'first letter', 'PRIVATE SPACE', 'Words written just for them. Timeless', Icons.email_rounded, Colors.pink, 'love_letters', 1),
      _m('letter_10', 'Poet at heart', '10 letters', 'PRIVATE SPACE', 'Ten letters. Ten pieces of your heart put into words', Icons.edit_rounded, Colors.blue, 'love_letters', 10),
      _m('surprise_1', 'Surprise!', 'first surprise', 'PRIVATE SPACE', 'The look on their face made it worth it', Icons.card_giftcard_rounded, Colors.orange, 'surprises_sent', 1),
      _m('surprise_plan', 'Thoughtful lover', 'scheduled', 'PRIVATE SPACE', 'You planned something beautiful before they even knew', Icons.alarm_rounded, Colors.redAccent, 'scheduled_surprises', 1),
      _m('biometric_on', 'Locked in', 'biometric on', 'PRIVATE SPACE', 'Your private world. Secured', Icons.touch_app_rounded, Colors.grey, 'biometric_enabled', 1),
      _m('vault_50', 'Vault keeper', '50 vault photos', 'PRIVATE SPACE', 'Fifty secrets safely stored between just you two', Icons.vpn_key_rounded, Colors.amber, 'vault_items', 50),
      _m('note_10', 'Note to self', '10 notes', 'PRIVATE SPACE', 'Ten notes. Ten little pieces of your relationship', Icons.assignment_rounded, Colors.blueGrey, 'private_notes', 10),

      // --- SPECIAL ---
      _m('one_week_app', 'One week together', '1 week on app', 'SPECIAL', 'Your story on NextMeet officially began', Icons.favorite_rounded, Colors.pink, 'streak', 7),
      _m('one_month_app', 'One month in', '1 month on app', 'SPECIAL', 'Thirty days of building something beautiful', Icons.favorite_rounded, Colors.red, 'streak', 30),
      _m('half_year_app', 'Half year milestone', '6 months on app', 'SPECIAL', 'Six months of NextMeet. Six months of you two', Icons.favorite_border_rounded, Colors.pinkAccent, 'streak', 180),
      _m('year_app', 'One year of NextMeet', '1 year on app', 'SPECIAL', 'A full year. Look how far you have come', Icons.celebration_rounded, Colors.orange, 'streak', 365),
      _m('early_adopter', 'Early adopter', 'early user', 'SPECIAL', 'You were here before everyone else', Icons.rocket_launch_rounded, Colors.pink, 'user_joined_early', 1),
      _m('insider', 'NextMeet Insider', 'premium active', 'SPECIAL', 'Supporting the growth of digital love', Icons.diamond_rounded, Colors.cyan, 'is_premium', 1),
      _m('streak_master', 'Streak master', 'all streaks', 'SPECIAL', 'Every streak badge earned. That is pure dedication', Icons.psychology_rounded, Colors.amberAccent, 'all_streaks_done', 1),
      _m('complete_lover', 'Complete lover', 'all categories', 'SPECIAL', 'Every badge. Every category. Every piece of NextMeet', Icons.emoji_events_rounded, Colors.amber, 'all_badges_done', 1),
    ];
  }

  static Milestone _m(
    String id,
    String title, 
    String subTitle, 
    String category, 
    String description, 
    IconData icon, 
    Color color,
    String taskId,
    int target,
  ) {
    return Milestone(
      id: id,
      title: title,
      subTitle: subTitle,
      category: category,
      description: description,
      icon: icon,
      color: color,
      reward: 'Badge Unlocked',
      tasks: [
        AchievementTask(id: taskId, name: subTitle, targetValue: target),
      ],
    );
  }
}
