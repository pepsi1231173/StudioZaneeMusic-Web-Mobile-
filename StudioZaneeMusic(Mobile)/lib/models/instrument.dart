class Instrument {
  final int id;
  final String name;
  final double price;
  final String? description;
  final String? img;
  final int? categoryId;
  bool isUnderMaintenance; // ✅ Bỏ final
  bool isRented; // ✅ Bỏ final

  static const String baseImageUrl = "http://10.0.2.2:5167";

  Instrument({
    required this.id,
    required this.name,
    required this.price,
    this.description,
    this.img,
    this.categoryId,
    required this.isUnderMaintenance,
    required this.isRented,
  });

  factory Instrument.fromJson(Map<String, dynamic> json) {
    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    final imagePath = json['imageUrl']?.toString();
    final imageUrl = (imagePath != null && imagePath.isNotEmpty)
        ? (imagePath.startsWith('http')
        ? imagePath
        : '$baseImageUrl$imagePath')
        : null;

    return Instrument(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      price: parsePrice(json['price']),
      description: json['description']?.toString(),
      img: imageUrl,
      categoryId: int.tryParse(json['categoryId']?.toString() ?? ''),
      isUnderMaintenance: json['isUnderMaintenance'] == true,
      isRented: json['isRented'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'description': description,
    'imageUrl': img,
    'categoryId': categoryId,
    'isUnderMaintenance': isUnderMaintenance,
    'isRented': isRented,
  };
}
