class User {
  final String fullName;
  final String email;
  final String? avatarUrl;

  User({
    required this.fullName,
    required this.email,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatarUrl'], // Có thể null nếu chưa có ảnh
    );
  }
}
