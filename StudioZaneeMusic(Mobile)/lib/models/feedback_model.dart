class FeedbackModel {
  final int? id;
  final String name;
  final String email;
  final String phone;
  final int rating;
  final String message;
  final DateTime? createdAt;

  FeedbackModel({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.rating,
    required this.message,
    this.createdAt,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      rating: json['rating'] ?? 0,
      message: json['message'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "email": email,
      "phone": phone,
      "rating": rating,
      "message": message,
    };
  }
}