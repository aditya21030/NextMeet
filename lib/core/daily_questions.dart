class DailyQuestions {
  static const List<String> questions = [
    "What is one song that always makes you think of me?",
    "If we had 24 hours together right now, what is the very first thing we would do?",
    "What small thing did I do recently that made you smile or made your heart warm?",
    "What is your absolute favorite memory of us in person so far?",
    "What is something cute that I do that you think I don't notice?",
    "What comfort food or snack do you crave most when you miss me?",
    "What was the exact moment or conversation where you knew you loved me?",
    "What are three words you would use to describe our relationship right now?",
    "If you could teleport to my side for just 10 minutes, what would we do?",
    "What is a dream trip or date we must go on during our next meetup?",
    "What is your favorite photo of us, and why?",
    "What is one habit or little quirk of mine that you secretly adore?",
    "What part of your day do you most look forward to sharing with me?",
    "What movie or series makes you want to cuddle up together?",
    "What is something I said that made you feel really loved and appreciated?",
    "If we could fall asleep together tonight, who would be the big spoon?",
    "What was the first impression you had of me when we first met or spoke?",
    "What is one promise about our future together that you hold close to your heart?",
    "What nickname of mine do you love hearing the most?",
    "What is one thing you can't wait for us to do as a routine when we close the distance?",
    "What is the funniest thing that has ever happened to us together?",
    "If you could send me a surprise package right now, what 3 things would be inside?",
    "What outfit of mine is your favorite?",
    "What is one compliment you've wanted to give me recently?",
    "What song would play in the background during our reunion hug at the airport?",
    "What made you proud of me this week?",
    "If we cooked dinner together tonight, what would we make?",
    "What is your favorite way to be comforted when you're having a stressful day?",
    "What is one question you've always wanted to ask me but never got around to?",
    "What is your favorite memory of us on a late-night phone call?",
    "What is the best gift or message I have ever given you?",
    "What is something new you'd love for us to try together on our next reunion?",
    "How has our relationship helped you grow as a person?",
    "What is your favorite inside joke between us?",
    "If our love story was a book, what would the title be?",
    "What is one physical feature of mine that you can never get enough of?",
    "What is the sweet thing I do that gives you butterflies?",
    "If we woke up in a cozy cabin in the mountains tomorrow, how would our morning go?",
    "What is something you wish I was there to help you with right now?",
    "What is one thing about our bond that makes you feel 100% safe and secure?",
    "What is your favorite season or holiday to spend together?",
    "If you could whisper one thing in my ear right now, what would it be?",
    "What does your ideal Sunday morning with me look like?",
    "What was the happiest day we've ever spent together?",
    "What is one thing you love about the way we communicate?",
    "What is a silly or funny fear of yours that only I know about?",
    "What is the sweetest dream you've ever had about us?",
    "If you could freeze time during one specific moment with me, which one would it be?",
    "What is one thing you love about my voice?",
    "How do you feel when you see my name pop up on your notifications?",
    "What is our ultimate countdown destination after NextMeet?",
    "What is one thing you want to tell me right now, straight from your heart?",
  ];

  static String getQuestionForDate(DateTime date) {
    // Deterministic selection based on day of year so both partners always see the identical question
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    final index = dayOfYear % questions.length;
    return questions[index];
  }

  static String getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
