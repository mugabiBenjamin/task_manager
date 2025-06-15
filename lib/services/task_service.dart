import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../core/constants/firebase_constants.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _tasksCollection =>
      _firestore.collection(FirebaseConstants.tasksCollection);

  // Create task
  Future<String> createTask(TaskModel task) async {
    try {
      final docRef = await _tasksCollection.add(task.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create task: $e');
    }
  }

  // Get tasks by user (created by or assigned to)
  Stream<List<TaskModel>> getTasksByUser(String userId) {
    return _tasksCollection
        .where(
          Filter.or(
            Filter(FirebaseConstants.createdByField, isEqualTo: userId),
            Filter(FirebaseConstants.assignedToField, arrayContains: userId),
          ),
        )
        .orderBy(FirebaseConstants.createdAtField, descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList(),
        );
  }

  // Get task by id
  Future<TaskModel?> getTaskById(String taskId) async {
    try {
      final doc = await _tasksCollection.doc(taskId).get();
      if (doc.exists) {
        return TaskModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get task: $e');
    }
  }

  // Update task
  Future<void> updateTask(String taskId, Map<String, dynamic> updates) async {
    try {
      updates[FirebaseConstants.updatedAtField] = Timestamp.now();
      await _tasksCollection.doc(taskId).update(updates);
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  // Delete task
  Future<void> deleteTask(String taskId) async {
    try {
      await _tasksCollection.doc(taskId).delete();
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  // Get tasks by status
  Stream<List<TaskModel>> getTasksByStatus(String userId, String status) {
    return _tasksCollection
        .where(
          Filter.or(
            Filter(FirebaseConstants.createdByField, isEqualTo: userId),
            Filter(FirebaseConstants.assignedToField, arrayContains: userId),
          ),
        )
        .where(FirebaseConstants.statusField, isEqualTo: status)
        .orderBy(FirebaseConstants.createdAtField, descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList(),
        );
  }

  // Get tasks by label
  Stream<List<TaskModel>> getTasksByLabel(String userId, String labelId) {
    return _tasksCollection
        .where(
          Filter.or(
            Filter(FirebaseConstants.createdByField, isEqualTo: userId),
            Filter(FirebaseConstants.assignedToField, arrayContains: userId),
          ),
        )
        .where(FirebaseConstants.labelsField, arrayContains: labelId)
        .orderBy(FirebaseConstants.createdAtField, descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList(),
        );
  }

  // Assign task to users
  Future<void> assignTask(String taskId, List<String> userIds) async {
    try {
      await updateTask(taskId, {FirebaseConstants.assignedToField: userIds});
    } catch (e) {
      throw Exception('Failed to assign task: $e');
    }
  }

  // Update task status
  Future<void> updateTaskStatus(String taskId, String status) async {
    try {
      await updateTask(taskId, {FirebaseConstants.statusField: status});
    } catch (e) {
      throw Exception('Failed to update task status: $e');
    }
  }
}
