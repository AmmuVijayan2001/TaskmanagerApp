class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    required this.themeMode,
  });

  final String id;
  final String name;
  final String email;
  final DateTime createdAt;
  final String themeMode;
}
