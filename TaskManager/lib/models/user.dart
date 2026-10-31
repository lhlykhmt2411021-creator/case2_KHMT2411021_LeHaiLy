class User {
  const User({
    required this.id,
    required this.fullName,
    required this.email,
    this.avatarUrl = '',
  });

  final String id;
  final String fullName;
  final String email;
  final String avatarUrl;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'fullName': fullName,
      'email': email,
      'avatarUrl': avatarUrl,
    };
  }
}
