import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/health_tip_model.dart';

/// Repository responsible for posting and reading health tips.
class HealthTipsRepository {
  final FirebaseFirestore _firestore;

  /// Creates a [HealthTipsRepository] with a Firestore instance.
  HealthTipsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Reference to the global health tips collection.
  CollectionReference get _tipsCollection => _firestore.collection('health_tips');

  /// Creates and stores a new health tip programmatically in Firestore.
  Future<void> postHealthTip({
    required String title,
    required String content,
    required String authorName,
    required String authorId,
    required String authorRole,
  }) async {
    // Write a new health tip document to the global collection.
    await _tipsCollection.add({
      'title': title,
      'content': content,
      'authorName': authorName,
      'authorId': authorId,
      'authorRole': authorRole,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Real-time stream of all posted health tips, sorted by newest first.
  Stream<List<HealthTipModel>> getHealthTipsStream() {
    // Return a real-time stream mapping snapshots to a list of models.
    return _tipsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HealthTipModel.fromFirestore(doc))
            .toList());
  }
}
