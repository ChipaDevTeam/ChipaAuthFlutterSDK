class ChipaUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool emailVerified;

  const ChipaUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.emailVerified = false,
  });

  factory ChipaUser.fromJson(Map<String, dynamic> json) => ChipaUser(
        uid: json['uid'] as String,
        email: json['email'] as String?,
        displayName: json['displayName'] as String?,
        photoUrl: json['photoURL'] as String?,
        emailVerified: (json['emailVerified'] as bool?) ?? false,
      );
}
