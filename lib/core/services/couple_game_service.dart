import 'package:cloud_firestore/cloud_firestore.dart';

/// NextMeet Couple Game Service
/// Handles real-time cloud sync, turn enforcement, and state management for couple games.
class CoupleGameService {
  static final CoupleGameService _instance = CoupleGameService._internal();
  factory CoupleGameService() => _instance;
  CoupleGameService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ===========================================================================
  // 1. TIC TAC TOE (Real-Time Synchronized & Turn-Enforced)
  // ===========================================================================
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamTicTacToe(String relId) {
    return _firestore
        .collection('relationships')
        .doc(relId)
        .collection('games')
        .doc('tictactoe')
        .snapshots();
  }

  Future<void> initTicTacToe(String relId, String firstTurnUid) async {
    final docRef = _firestore
        .collection('relationships')
        .doc(relId)
        .collection('games')
        .doc('tictactoe');
    final doc = await docRef.get().timeout(const Duration(seconds: 8));
    if (!doc.exists) {
      await docRef.set({
        'board': List.filled(9, ''),
        'currentTurn': firstTurnUid,
        'winner': null,
        'scoreU1': 0,
        'scoreU2': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 8));
    }
  }

  Future<void> makeTicTacToeMove(
    String relId,
    List<String> newBoard,
    String nextTurnUid, {
    String? winner,
    bool incrementU1 = false,
    bool incrementU2 = false,
  }) async {
    final docRef = _firestore
        .collection('relationships')
        .doc(relId)
        .collection('games')
        .doc('tictactoe');
    final Map<String, dynamic> updates = {
      'board': newBoard,
      'currentTurn': nextTurnUid,
      'winner': winner,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (incrementU1) updates['scoreU1'] = FieldValue.increment(1);
    if (incrementU2) updates['scoreU2'] = FieldValue.increment(1);
    await docRef.set(updates, SetOptions(merge: true)).timeout(const Duration(seconds: 8));
  }

  Future<void> resetTicTacToe(String relId, String startingTurnUid) async {
    final docRef = _firestore
        .collection('relationships')
        .doc(relId)
        .collection('games')
        .doc('tictactoe');
    await docRef.set({
      'board': List.filled(9, ''),
      'currentTurn': startingTurnUid,
      'winner': null,
      'lastReaction': null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).timeout(const Duration(seconds: 8));
  }

  Future<void> sendGameReaction(String relId, String gameName, String reaction, String senderName) async {
    await _firestore
        .collection('relationships')
        .doc(relId)
        .collection('games')
        .doc(gameName)
        .set({
      'lastReaction': reaction,
      'lastReactionBy': senderName,
      'reactionTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).timeout(const Duration(seconds: 8));
  }

  // ===========================================================================
  // 2. CONNECT FOUR / HEARTS IN A ROW (Real-Time 7x6 Grid)
  // ===========================================================================
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamConnectFour(String relId) {
    return _firestore
        .collection('relationships')
        .doc(relId)
        .collection('games')
        .doc('connect_four')
        .snapshots();
  }

  Future<void> initConnectFour(String relId, String firstTurnUid) async {
    final docRef = _firestore
        .collection('relationships')
        .doc(relId)
        .collection('games')
        .doc('connect_four');
    final doc = await docRef.get().timeout(const Duration(seconds: 8));
    if (!doc.exists) {
      await docRef.set({
        // 6 rows x 7 cols = 42 cells (0: empty, 1: U1 Pink, 2: U2 Violet)
        'board': List.filled(42, 0),
        'currentTurn': firstTurnUid,
        'winner': null,
        'scoreU1': 0,
        'scoreU2': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 8));
    }
  }

  Future<void> makeConnectFourMove(
    String relId,
    List<int> newBoard,
    String nextTurnUid, {
    String? winner,
    bool incrementU1 = false,
    bool incrementU2 = false,
  }) async {
    final docRef = _firestore
        .collection('relationships')
        .doc(relId)
        .collection('games')
        .doc('connect_four');
    final Map<String, dynamic> updates = {
      'board': newBoard,
      'currentTurn': nextTurnUid,
      'winner': winner,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (incrementU1) updates['scoreU1'] = FieldValue.increment(1);
    if (incrementU2) updates['scoreU2'] = FieldValue.increment(1);
    await docRef.set(updates, SetOptions(merge: true)).timeout(const Duration(seconds: 8));
  }

  Future<void> resetConnectFour(String relId, String startingTurnUid) async {
    final docRef = _firestore
        .collection('relationships')
        .doc(relId)
        .collection('games')
        .doc('connect_four');
    await docRef.set({
      'board': List.filled(42, 0),
      'currentTurn': startingTurnUid,
      'winner': null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).timeout(const Duration(seconds: 8));
  }

  // ===========================================================================
  // 3. NEVER HAVE I EVER (Simultaneous Real-Time Answer Reveal)
  // ===========================================================================
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamNeverHaveIEver(String relId) {
    return _firestore
        .collection('relationships')
        .doc(relId)
        .collection('games')
        .doc('never_have_i_ever')
        .snapshots();
  }

  Future<void> submitNeverHaveIEverAnswer(String relId, int promptIndex, String uid, bool haveDone) async {
    final docRef = _firestore
        .collection('relationships')
        .doc(relId)
        .collection('games')
        .doc('never_have_i_ever');
    final snap = await docRef.get().timeout(const Duration(seconds: 8));
    if (!snap.exists) {
      await docRef.set({
        'promptIndex': promptIndex,
        'answers': {uid: haveDone},
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 8));
    } else {
      await docRef.update({
        'promptIndex': promptIndex,
        'answers.$uid': haveDone,
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 8));
    }
  }

  Future<void> nextNeverHaveIEverPrompt(String relId, int nextIndex) async {
    final docRef = _firestore
        .collection('relationships')
        .doc(relId)
        .collection('games')
        .doc('never_have_i_ever');
    await docRef.set({
      'promptIndex': nextIndex,
      'answers': {},
      'updatedAt': FieldValue.serverTimestamp(),
    }).timeout(const Duration(seconds: 8));
  }

  // ===========================================================================
  // 4. ROMANTIC WHEEL OF DATES (Synchronized Spin)
  // ===========================================================================
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamWheel(String relId) {
    return _firestore
        .collection('relationships')
        .doc(relId)
        .collection('games')
        .doc('wheel_of_dates')
        .snapshots();
  }

  Future<void> spinWheel(String relId, int targetIndex, String challengeTitle, String spunByName) async {
    final docRef = _firestore
        .collection('relationships')
        .doc(relId)
        .collection('games')
        .doc('wheel_of_dates');
    await docRef.set({
      'targetIndex': targetIndex,
      'challengeTitle': challengeTitle,
      'spunByName': spunByName,
      'spinTimestamp': DateTime.now().millisecondsSinceEpoch,
      'updatedAt': FieldValue.serverTimestamp(),
    }).timeout(const Duration(seconds: 8));
  }

  // ===========================================================================
  // 5. DRAW TOGETHER (Real-Time Shared Canvas)
  // ===========================================================================
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamDrawing(String relId) {
    return _firestore
        .collection('relationships')
        .doc(relId)
        .collection('games')
        .doc('drawing')
        .snapshots();
  }

  Future<void> updateDrawing(String relId, List<Map<String, dynamic>> serializedLines) async {
    final docRef = _firestore
        .collection('relationships')
        .doc(relId)
        .collection('games')
        .doc('drawing');
    await docRef.set({
      'lines': serializedLines,
      'updatedAt': FieldValue.serverTimestamp(),
    }).timeout(const Duration(seconds: 8));
  }

  Future<void> clearDrawing(String relId) async {
    final docRef = _firestore
        .collection('relationships')
        .doc(relId)
        .collection('games')
        .doc('drawing');
    await docRef.set({
      'lines': [],
      'updatedAt': FieldValue.serverTimestamp(),
    }).timeout(const Duration(seconds: 8));
  }

  // ===========================================================================
  // 6. DOTS & HEART BOXES (Real-Time Territory Game)
  // ===========================================================================
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamDotsAndBoxes(String relId) {
    return _firestore
        .collection('relationships')
        .doc(relId)
        .collection('games')
        .doc('dots_and_boxes')
        .snapshots();
  }

  Future<void> initDotsAndBoxes(String relId, String firstTurnUid) async {
    final docRef = _firestore
        .collection('relationships')
        .doc(relId)
        .collection('games')
        .doc('dots_and_boxes');
    final doc = await docRef.get().timeout(const Duration(seconds: 8));
    if (!doc.exists) {
      await docRef.set({
        'hLines': List.filled(12, 0),
        'vLines': List.filled(12, 0),
        'boxes': List.filled(9, 0),
        'currentTurn': firstTurnUid,
        'scoreU1': 0,
        'scoreU2': 0,
        'winner': null,
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 8));
    }
  }

  Future<void> makeDotsAndBoxesMove(
    String relId, {
    required List<int> hLines,
    required List<int> vLines,
    required List<int> boxes,
    required String nextTurnUid,
    required int scoreU1,
    required int scoreU2,
    String? winner,
  }) async {
    final docRef = _firestore
        .collection('relationships')
        .doc(relId)
        .collection('games')
        .doc('dots_and_boxes');
    await docRef.set({
      'hLines': hLines,
      'vLines': vLines,
      'boxes': boxes,
      'currentTurn': nextTurnUid,
      'scoreU1': scoreU1,
      'scoreU2': scoreU2,
      'winner': winner,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).timeout(const Duration(seconds: 8));
  }

  Future<void> resetDotsAndBoxes(String relId, String startingTurnUid) async {
    final docRef = _firestore
        .collection('relationships')
        .doc(relId)
        .collection('games')
        .doc('dots_and_boxes');
    await docRef.set({
      'hLines': List.filled(12, 0),
      'vLines': List.filled(12, 0),
      'boxes': List.filled(9, 0),
      'currentTurn': startingTurnUid,
      'scoreU1': 0,
      'scoreU2': 0,
      'winner': null,
      'updatedAt': FieldValue.serverTimestamp(),
    }).timeout(const Duration(seconds: 8));
  }

  // ===========================================================================
  // 7. ROCK PAPER KISS (Real-Time Simultaneous Hand Clash)
  // ===========================================================================
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamRockPaperKiss(String relId) {
    return _firestore
        .collection('relationships')
        .doc(relId)
        .collection('games')
        .doc('rock_paper_kiss')
        .snapshots();
  }

  Future<void> submitRPSMove(String relId, String uid, String moveName) async {
    final docRef = _firestore
        .collection('relationships')
        .doc(relId)
        .collection('games')
        .doc('rock_paper_kiss');
    final snap = await docRef.get().timeout(const Duration(seconds: 8));
    if (!snap.exists) {
      await docRef.set({
        'moves': {uid: moveName},
        'round': 1,
        'scoreU1': 0,
        'scoreU2': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 8));
    } else {
      await docRef.update({
        'moves.$uid': moveName,
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 8));
    }
  }

  Future<void> nextRPSRound(String relId, {int? scoreU1, int? scoreU2}) async {
    final docRef = _firestore
        .collection('relationships')
        .doc(relId)
        .collection('games')
        .doc('rock_paper_kiss');
    final Map<String, dynamic> updates = {
      'moves': {},
      'round': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (scoreU1 != null) updates['scoreU1'] = scoreU1;
    if (scoreU2 != null) updates['scoreU2'] = scoreU2;
    await docRef.set(updates, SetOptions(merge: true)).timeout(const Duration(seconds: 8));
  }

  Future<void> resetRPSGame(String relId) async {
    final docRef = _firestore
        .collection('relationships')
        .doc(relId)
        .collection('games')
        .doc('rock_paper_kiss');
    await docRef.set({
      'moves': {},
      'round': 1,
      'scoreU1': 0,
      'scoreU2': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    }).timeout(const Duration(seconds: 8));
  }

  // ===========================================================================
  // 8. WOULD YOU RATHER (Real-Time Couple Choice Matcher)
  // ===========================================================================
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamWouldYouRather(String relId) {
    return _firestore
        .collection('relationships')
        .doc(relId)
        .collection('games')
        .doc('would_you_rather')
        .snapshots();
  }

  Future<void> submitWouldYouRatherChoice(String relId, int dilemmaIndex, String uid, int choiceIndex) async {
    final docRef = _firestore
        .collection('relationships')
        .doc(relId)
        .collection('games')
        .doc('would_you_rather');
    final snap = await docRef.get().timeout(const Duration(seconds: 8));
    if (!snap.exists) {
      await docRef.set({
        'dilemmaIndex': dilemmaIndex,
        'choices': {uid: choiceIndex},
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 8));
    } else {
      await docRef.update({
        'dilemmaIndex': dilemmaIndex,
        'choices.$uid': choiceIndex,
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 8));
    }
  }

  Future<void> nextWouldYouRather(String relId, int nextIndex) async {
    final docRef = _firestore
        .collection('relationships')
        .doc(relId)
        .collection('games')
        .doc('would_you_rather');
    await docRef.set({
      'dilemmaIndex': nextIndex,
      'choices': {},
      'updatedAt': FieldValue.serverTimestamp(),
    }).timeout(const Duration(seconds: 8));
  }

  // ===========================================================================
  // 9. HOW WELL DO YOU KNOW ME? (Real-Time Couple Quiz)
  // ===========================================================================
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamQuiz(String relId) {
    return _firestore
        .collection('relationships')
        .doc(relId)
        .collection('games')
        .doc('couple_quiz')
        .snapshots();
  }

  Future<void> submitQuizAnswer(String relId, int questionIndex, String uid, int answerIndex) async {
    final docRef = _firestore
        .collection('relationships')
        .doc(relId)
        .collection('games')
        .doc('couple_quiz');
    final snap = await docRef.get().timeout(const Duration(seconds: 8));
    if (!snap.exists) {
      await docRef.set({
        'questionIndex': questionIndex,
        'answers': {uid: answerIndex},
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 8));
    } else {
      await docRef.update({
        'questionIndex': questionIndex,
        'answers.$uid': answerIndex,
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 8));
    }
  }

  Future<void> nextQuizQuestion(String relId, int nextIndex, {bool incrementScore1 = false, bool incrementScore2 = false}) async {
    final docRef = _firestore
        .collection('relationships')
        .doc(relId)
        .collection('games')
        .doc('couple_quiz');
    final Map<String, dynamic> updates = {
      'questionIndex': nextIndex,
      'answers': {},
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (incrementScore1) updates['scoreU1'] = FieldValue.increment(1);
    if (incrementScore2) updates['scoreU2'] = FieldValue.increment(1);
    await docRef.set(updates, SetOptions(merge: true)).timeout(const Duration(seconds: 8));
  }

  Future<void> resetQuiz(String relId) async {
    final docRef = _firestore
        .collection('relationships')
        .doc(relId)
        .collection('games')
        .doc('couple_quiz');
    await docRef.set({
      'questionIndex': 0,
      'answers': {},
      'scoreU1': 0,
      'scoreU2': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    }).timeout(const Duration(seconds: 8));
  }

  // ===========================================================================
  // 10. TRUTH OR DARE (Real-Time Shared Challenge Stream)
  // ===========================================================================
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamTruthOrDare(String relId) {
    return _firestore
        .collection('relationships')
        .doc(relId)
        .collection('games')
        .doc('truth_or_dare')
        .snapshots();
  }

  Future<void> sendTruthOrDareChallenge(
    String relId, {
    required String type, // 'truth' or 'dare'
    required String prompt,
    required String senderName,
    String? senderUid,
    required String tag,
    required String emoji,
  }) async {
    final docRef = _firestore
        .collection('relationships')
        .doc(relId)
        .collection('games')
        .doc('truth_or_dare');
    await docRef.set({
      'type': type,
      'prompt': prompt,
      'senderName': senderName,
      'senderUid': senderUid,
      'tag': tag,
      'emoji': emoji,
      'status': 'sent',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'updatedAt': FieldValue.serverTimestamp(),
    }).timeout(const Duration(seconds: 8));
  }

  Future<void> completeTruthOrDareChallenge(String relId) async {
    final docRef = _firestore
        .collection('relationships')
        .doc(relId)
        .collection('games')
        .doc('truth_or_dare');
    await docRef.update({
      'status': 'completed',
      'updatedAt': FieldValue.serverTimestamp(),
    }).timeout(const Duration(seconds: 8));
  }
}
