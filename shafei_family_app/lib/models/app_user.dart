class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    this.branch = '',
    this.approved = false,
    this.isAdmin = false,
  });

  final String uid;
  final String name;
  final String email;
  final String phone;

  /// فرع العائلة / اسم الأب، يساعد في التعرف على الشخص.
  final String branch;
  final bool approved;
  final bool isAdmin;

  factory AppUser.fromMap(String uid, Map<String, dynamic> m) => AppUser(
        uid: uid,
        name: (m['name'] ?? '') as String,
        email: (m['email'] ?? '') as String,
        phone: (m['phone'] ?? '') as String,
        branch: (m['branch'] ?? '') as String,
        approved: m['approved'] == true,
        isAdmin: m['isAdmin'] == true,
      );
}
