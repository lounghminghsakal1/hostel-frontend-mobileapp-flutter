enum UserRole {
  student,
  hostelAdmin;

  String get label => switch (this) {
        UserRole.student => 'Student',
        UserRole.hostelAdmin => 'Hostel Admin',
      };

  /// Value persisted to secure storage / sent to the API.
  String get storageValue => switch (this) {
        UserRole.student => 'STUDENT',
        UserRole.hostelAdmin => 'HOSTEL_ADMIN',
      };

  static UserRole fromStorageValue(String? value) => switch (value) {
        'HOSTEL_ADMIN' => UserRole.hostelAdmin,
        _ => UserRole.student,
      };
}
