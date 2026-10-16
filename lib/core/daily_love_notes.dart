import 'package:intl/intl.dart';

class DailyLoveNotes {
  static final List<String> _notes = [
    "No matter how many miles separate us tonight, my heart beats to the exact rhythm of yours.",
    "Thinking of your smile is the sweetest pause in my busy day. I love you more than words can hold.",
    "If I could fly across every time zone just to hold your hand for ten seconds, I would do it without hesitation.",
    "You are my favorite thought when I wake up and my softest whisper before I fall asleep.",
    "Distance only shows how strong our love is. Every sunset brings us one day closer to our next hug.",
    "I looked at the moon tonight and smiled, knowing we are both standing beneath the very same sky.",
    "You turned my ordinary world into an extraordinary love story. Counting down the seconds until I see you.",
    "Whenever I miss you, I close my eyes and feel your warmth right beside me. You are my forever home.",
    "A day without talking to you feels like a song without music. You are the harmony in my life.",
    "I don't just love you for who you are; I love who I become every time I am with you.",
    "Our reunion will be the sweetest moment of my life. Until then, you have my whole heart in your hands.",
    "Distance means so little when someone means so much. You are my greatest adventure and my safest haven.",
    "Just a reminder: someone miles away is utterly and hopelessly in love with you today.",
    "I carry you in my thoughts, in my prayers, and in every single heartbeat. Stay safe, my love.",
    "One day soon, we won't have to say goodbye through a screen. We will just say 'goodnight' in person.",
    "Your voice is my favorite melody. Even a two-minute call can turn my entire week around.",
    "Loving you from afar has taught me patience, but holding you close will always be my greatest joy.",
    "You are the dream I never want to wake up from, and the reality I am forever grateful for.",
    "Every plane ticket, every train ride, and every second of waiting will all be worth it the moment I hold you.",
    "You give me butterflies from hundreds of miles away. That is pure magic.",
    "Thank you for being my anchor when life gets stormy and my sunshine when the skies are grey.",
    "The best part of my day is always the part where I get to talk to you.",
    "Our love is not measured in kilometers, but in the depth of our connection and the strength of our promises.",
    "If loving you was a journey, I would walk it barefoot across the whole world just to reach your arms.",
    "You are the missing piece that makes my world make sense. Forever yours, no matter the distance.",
    "I hope you feel my love wrapped around you today like a warm, comforting blanket.",
    "Every day spent loving you is another day closer to the life we are building together.",
    "Even when we are apart, we share the same dreams, the same stars, and the same unbreakable bond.",
    "You are my answered prayer, my sweetest reality, and the love of my lifetime.",
    "My heart never feels distant from yours; it knows exactly where it belongs.",
    "Whenever you feel tired or lonely today, remember that you are cherished deeply and unconditionally.",
    "No ocean is wide enough to drown the love I have for you. You are my forever person.",
    "The countdown to our next meet is my favorite number in the entire world.",
    "I fall in love with you a little more each morning, and miss you a little more each night.",
    "You are worth every second of the wait, every mile of the distance, and every ounce of my devotion.",
    "In a world of noise and chaos, your love is the only peace I ever need.",
    "Hold on to this love today. We are writing a love story that will inspire our future forever.",
  ];

  /// Returns today's date key in YYYY-MM-DD format
  static String getTodayKey([DateTime? date]) {
    final d = date ?? DateTime.now();
    return DateFormat('yyyy-MM-dd').format(d);
  }

  /// Returns a deterministic romantic love note for any given day
  static String getNoteForDate(DateTime date) {
    // Deterministic 1-365 index calculation
    final startOfYear = DateTime(date.year, 1, 1);
    final dayOfYear = date.difference(startOfYear).inDays;
    return _notes[dayOfYear % _notes.length];
  }

  /// Returns today's love note
  static String getTodayNote() {
    return getNoteForDate(DateTime.now());
  }
}
