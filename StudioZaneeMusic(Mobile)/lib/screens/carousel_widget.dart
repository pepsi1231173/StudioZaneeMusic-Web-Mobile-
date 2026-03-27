import 'dart:async';
import 'package:flutter/material.dart';
import '../models/product.dart';
import 'product_detail_screen.dart';

class OverlapCarousel extends StatefulWidget {
  const OverlapCarousel({super.key});

  @override
  State<OverlapCarousel> createState() => _OverlapCarouselState();
}

class _OverlapCarouselState extends State<OverlapCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.55);
  int _currentPage = 0;
  Timer? _timer;

  // Danh sách nhạc cụ
  final List<Map<String, dynamic>> _images = [
    {
      "image": "assets/images/guitar_ibanez.jpg",
      "title": "Guitar Ibanez",
      "category": "Guitar",
      "price": 150000,
      "desc": "Cây guitar Ibanez với âm thanh mạnh mẽ, thích hợp chơi rock.",
    },
    {
      "image": "assets/images/guitar_takamine.jpg",
      "title": "Guitar Takamine",
      "category": "Guitar",
      "price": 120000,
      "desc": "Guitar Takamine cho âm thanh ấm và tự nhiên.",
    },
    {
      "image": "assets/images/guitar_fender.jpg",
      "title": "Guitar Fender",
      "category": "Guitar",
      "price": 180000,
      "desc": "Fender nổi tiếng với chất âm đỉnh cao cho biểu diễn chuyên nghiệp.",
    },
    {
      "image": "assets/images/drums_pearl.jpg",
      "title": "Drums Pearl",
      "category": "Drum",
      "price": 200000,
      "desc": "Bộ trống Pearl cao cấp với âm thanh uy lực.",
    },
    {
      "image": "assets/images/drums_yamaha.jpg",
      "title": "Drums Yamaha",
      "category": "Drum",
      "price": 170000,
      "desc": "Trống Yamaha – lựa chọn hàng đầu cho phòng thu.",
    },
    {
      "image": "assets/images/drums_mapex.jpg",
      "title": "Drums Mapex",
      "category": "Drum",
      "price": 160000,
      "desc": "Trống Mapex với thiết kế mạnh mẽ, độ bền cao.",
    },
    {
      "image": "assets/images/keyboard_roland.jpg",
      "title": "Keyboard Roland",
      "category": "Keyboard",
      "price": 140000,
      "desc": "Roland với âm thanh điện tử đặc trưng, thích hợp chơi live.",
    },
    {
      "image": "assets/images/keyboard_yamaha.jpg",
      "title": "Keyboard Yamaha",
      "category": "Keyboard",
      "price": 130000,
      "desc": "Keyboard Yamaha với đa dạng tiếng nhạc và hiệu ứng.",
    },
    {
      "image": "assets/images/keyboard_korg.jpg",
      "title": "Keyboard Korg",
      "category": "Keyboard",
      "price": 155000,
      "desc": "Korg – dòng keyboard được nhiều nghệ sĩ tin dùng.",
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      int next = (_currentPage + 1) % _images.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ====== CAROUSEL ======
        SizedBox(
          height: 280,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _images.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              final item = _images[index]; // ✅ Khai báo đúng biến
              double scale = index == _currentPage ? 1.0 : 0.82;
              double opacity = index == _currentPage ? 1.0 : 0.6;

              return GestureDetector(
                onTap: () {
                  final product = Product(
                    id: index + 1,
                    name: item["title"]!,
                    price: (item["price"] ?? 0).toDouble(),
                    description: item["desc"] ?? "",
                    imageUrl: item["image"]!,
                    categoryName: item["category"] ?? "Không rõ",
                    isUnderMaintenance: false,
                    isRented: false,
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(product: product),
                    ),
                  );
                },
                child: AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    return Center(
                      child: Transform.scale(
                        scale: scale,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 400),
                          opacity: opacity,
                          child: Container(
                            width: 230,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: index == _currentPage
                                    ? Colors.amberAccent
                                    : Colors.amber.withOpacity(0.3),
                                width: index == _currentPage ? 4 : 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(25),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.asset(
                                    item["image"]!,
                                    fit: BoxFit.cover,
                                  ),
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            Colors.black.withOpacity(0.7),
                                            Colors.transparent
                                          ],
                                        ),
                                      ),
                                      child: Text(
                                        item["title"]!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black54,
                                              blurRadius: 6,
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
