import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  String formatCurrency(double value) {
    final format = NumberFormat("#,###", "vi_VN");
    return "${format.format(value)} VNĐ";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // ✅ Cho phép AppBar đè lên background
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.4), // ✅ đen mờ
        elevation: 0,
        centerTitle: true,
        title: Text(
          product.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(color: Colors.black45, blurRadius: 8),
            ],
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white), // nút back trắng
      ),
      body: Stack(
        children: [
          // ✅ Background chính (ảnh BACKROUND.jpg)
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/BACKROUND.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // ✅ Lớp phủ gradient tối giúp chữ rõ hơn
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.black.withOpacity(0.5),
                  Colors.black.withOpacity(0.9),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // ✅ Nội dung chính
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 100), // chừa khoảng cho AppBar trong suốt
                // Ảnh sản phẩm
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amberAccent.withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      product.imageUrl, // 🔹 Ảnh nhạc cụ trong assets
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Thông tin chi tiết
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 6),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Danh mục: ${product.categoryName}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Giá thuê: ${formatCurrency(product.price)}",
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        product.description?.isNotEmpty == true
                            ? product.description!
                            : "Không có mô tả.",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 25),

                      // Trạng thái
                      Row(
                        children: [
                          Icon(
                            product.isUnderMaintenance
                                ? Icons.build
                                : product.isRented
                                ? Icons.lock
                                : Icons.check_circle,
                            color: product.isUnderMaintenance
                                ? Colors.orange
                                : product.isRented
                                ? Colors.red
                                : Colors.greenAccent,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            product.isUnderMaintenance
                                ? "Đang bảo trì"
                                : product.isRented
                                ? "Đang được thuê"
                                : "Sẵn sàng cho thuê",
                            style: TextStyle(
                              color: product.isUnderMaintenance
                                  ? Colors.orange
                                  : product.isRented
                                  ? Colors.red
                                  : Colors.greenAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              shadows: const [
                                Shadow(color: Colors.black45, blurRadius: 4),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
