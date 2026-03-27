class MusicRequest {
  int? id;
  String musicGenre;
  String musicDescription;
  String customerName;
  String customerEmail;
  String customerPhone;
  DateTime? createdAt;
  String status; // ✅ để mặc định là "pending" thay vì nullable

  MusicRequest({
    this.id,
    required this.musicGenre,
    required this.musicDescription,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    this.createdAt,
    this.status = "pending", // ✅ mặc định đúng với backend
  });

  factory MusicRequest.fromJson(Map<String, dynamic> json) => MusicRequest(
    id: json['id'],
    musicGenre: json['musicGenre'] ?? '',
    musicDescription: json['musicDescription'] ?? '',
    customerName: json['customerName'] ?? '',
    customerEmail: json['customerEmail'] ?? '',
    customerPhone: json['customerPhone'] ?? '',
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    status: json['status'] ?? 'pending',
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'musicGenre': musicGenre,
    'musicDescription': musicDescription,
    'customerName': customerName,
    'customerEmail': customerEmail,
    'customerPhone': customerPhone,
    'status': status, // ✅ backend ASP.NET yêu cầu có field này
  };
}
