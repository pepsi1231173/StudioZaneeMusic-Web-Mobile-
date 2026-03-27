class Product {
  final int id;
  final String name;
  final double price;
  final String? description;
  final String imageUrl;
  final String categoryName;
  final bool isUnderMaintenance;
  final bool isRented;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.description,
    required this.imageUrl,
    required this.categoryName,
    required this.isUnderMaintenance,
    required this.isRented,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json["id"],
      name: json["name"] ?? "",
      price: (json["price"] ?? 0).toDouble(),
      description: json["description"],
      imageUrl: json["imageUrl"] ?? "",
      categoryName: json["categoryName"] ?? "Không rõ",
      isUnderMaintenance: json["isUnderMaintenance"] == 1,
      isRented: json["isRented"] == 1,
    );
  }
}
