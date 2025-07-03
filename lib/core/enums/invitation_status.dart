enum InvitationStatus {
  none('none', 'None'),
  pending('pending', 'Pending'),
  accepted('accepted', 'Accepted'),
  declined('declined', 'Declined'),
  expired('expired', 'Expired');

  const InvitationStatus(this.value, this.displayName);
  final String value;
  final String displayName;

  static InvitationStatus fromString(String value) {
    return InvitationStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => InvitationStatus.none,
    );
  }
}
