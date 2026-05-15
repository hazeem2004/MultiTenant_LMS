import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/submission.dart';

class SubmissionRepository {
  final FirebaseFirestore _firestore;
  SubmissionRepository(this._firestore);

  CollectionReference<Submission> get _submissionsRef =>
      _firestore.collection('submissions').withConverter<Submission>(
            fromFirestore: (snapshot, _) =>
                Submission.fromMap(snapshot.data()!, snapshot.id),
            toFirestore: (submission, _) => submission.toMap(),
          );

  Stream<List<Submission>> watchSubmissionsForAssignment(String assignmentId) {
    return _submissionsRef
        .where('assignmentId', isEqualTo: assignmentId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<Submission?> watchStudentSubmission(String studentId, String assignmentId) {
    return _submissionsRef
        .where('studentId', isEqualTo: studentId)
        .where('assignmentId', isEqualTo: assignmentId)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty ? snapshot.docs.first.data() : null);
  }

  Future<List<Submission>> getSubmissionsForAssignment(String assignmentId) async {
    final snapshot = await _submissionsRef
        .where('assignmentId', isEqualTo: assignmentId)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<Submission?> getStudentSubmission(String studentId, String assignmentId) async {
    final snapshot = await _submissionsRef
        .where('studentId', isEqualTo: studentId)
        .where('assignmentId', isEqualTo: assignmentId)
        .limit(1)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.data();
    }
    return null;
  }

  Future<void> submitAssignment(Submission submission) async {
    // Check if exists to update or add new
    final existing = await getStudentSubmission(submission.studentId, submission.assignmentId);
    if (existing != null) {
      await _submissionsRef.doc(existing.id).set(submission);
    } else {
      await _submissionsRef.add(submission);
    }
  }

  Future<void> gradeSubmission(String submissionId, SubmissionStatus status, String feedback) async {
    await _submissionsRef.doc(submissionId).update({
      'status': status.name,
      'instructorFeedback': feedback,
    });
  }
}

final submissionRepositoryProvider = Provider<SubmissionRepository>((ref) {
  return SubmissionRepository(FirebaseFirestore.instance);
});
