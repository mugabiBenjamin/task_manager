enum TaskStatus {
  notStarted('not_started', 'Not Started'),
  inProgress('in_progress', 'In Progress'),
  complete('complete', 'Complete');

  const TaskStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  static TaskStatus fromString(String value) {
    return TaskStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => TaskStatus.notStarted,
    );
  }

  @override
  String toString() => value;
}
