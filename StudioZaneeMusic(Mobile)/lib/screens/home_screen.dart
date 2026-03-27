import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'profile_screen.dart';
import 'room_list_screen.dart';
import 'carousel_widget.dart'; // 👈 import carousel
import 'service_history_screen.dart';
import 'more/room_schedule_page.dart';
import 'more/recording_packages_page.dart';
import 'more/voucher_page.dart';
import 'more/support_policy_page.dart';
import 'instrument_list_page.dart';
import '../models/product.dart';
import 'product_detail_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'instrument_list_screen.dart';
import 'recording_form_screen.dart';
import 'music_request_form_screen.dart';
import 'feedback_form_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const HomeScreen({super.key, required this.userData});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentImage = 0;
  late Timer _timer;
  final PageController _pageController = PageController(viewportFraction: 0.7);
  int _selectedIndex = 0;

  List<Map<String, dynamic>> _filteredItems = [];
  List<Product> _searchedProducts = [];
  bool _isSearching = false;

  final TextEditingController _searchController = TextEditingController();

  final List<String> _carouselImages = [
    "assets/images/HAHD1.jpg",
    "assets/images/HAHD2.jpg",
    "assets/images/HAHD3.jpg",
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _currentImage = (_currentImage + 1) % _carouselImages.length;
      _pageController.animateToPage(
        _currentImage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // ✅ Gọi API tìm kiếm sản phẩm theo tên hoặc loại
  Future<void> _searchProducts(String keyword) async {
    if (keyword.isEmpty) {
      setState(() {
        _searchedProducts.clear();
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final encodedKeyword = Uri.encodeComponent(keyword);
      final url = Uri.parse("http://10.0.2.2:5167/api/products/by-name/$encodedKeyword");
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final List data = json.decode(res.body);

        setState(() {
          _searchedProducts = data.map((json) => Product.fromJson(json)).toList();
        });
      } else {
        setState(() => _searchedProducts = []);
      }
    } catch (e) {
      debugPrint("❌ Lỗi tìm sản phẩm: $e");
      setState(() => _searchedProducts = []);
    } finally {
      setState(() => _isSearching = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final String username = widget.userData['fullName'] ?? "Khách";
    final String? avatarPath = widget.userData['avatar'];
    final String avatarUrl = (avatarPath != null && avatarPath.isNotEmpty)
        ? (avatarPath.startsWith("http")
        ? avatarPath
        : "http://192.168.1.22:5167$avatarPath")
        : "http://192.168.1.22:5167/images/avatars/default-avatar.svg";

    // 🔹 Danh mục tìm kiếm hiển thị
    final List<Map<String, dynamic>> _searchItems = [
      {"name": "Phòng A", "icon": Icons.meeting_room, "page": RoomListScreen(userData: widget.userData)},
      {"name": "Phòng B", "icon": Icons.meeting_room, "page": RoomListScreen(userData: widget.userData)},
      {"name": "Phòng C", "icon"  : Icons.meeting_room, "page": RoomListScreen(userData: widget.userData)},
      {"name": "Thu Âm", "icon": Icons.headphones, "page": const RecordingPackagesPage()},
      {"name": "Làm Nhạc", "icon": Icons.library_music, "page": const RecordingPackagesPage()},
      {"name": "Lịch Phòng", "icon": Icons.calendar_month, "page": const RoomSchedulePage()},
      {"name": "Voucher", "icon": Icons.card_giftcard, "page": const VoucherPage()},
      {"name": "Chính Sách & Hỗ Trợ", "icon": Icons.help_outline, "page": const SupportPolicyPage()},

      // 🎸 Các loại nhạc cụ → dùng lại InstrumentListPage
      {"name": "Guitar", "icon": Icons.music_note, "page": InstrumentListPage(initialKeyword: "guitar")},
      {"name": "Trống", "icon": Icons.music_video, "page": InstrumentListPage(initialKeyword: "trống")},
      {"name": "Amplifier", "icon": Icons.speaker, "page": InstrumentListPage(initialKeyword: "amplifier")},
      {"name": "Mixer", "icon": Icons.settings_input_component, "page": InstrumentListPage(initialKeyword: "mixer")},
      {"name": "Violin", "icon": Icons.queue_music, "page": InstrumentListPage(initialKeyword: "violin")},
      {"name": "Tất cả", "icon": Icons.list, "page": const InstrumentListPage(initialKeyword: "")},
    ];

    // ===== BODY HOME =====
    final homeContent = Stack(
      children: [
        Positioned.fill(
          child: Image.asset('assets/images/BACKROUND.jpg', fit: BoxFit.cover),
        ),
        Positioned.fill(
          child: Container(color: Colors.black.withOpacity(0.55)),
        ),
        Column(
          children: [
            _buildHeader(username, avatarUrl),
            const SizedBox(height: 8),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // ===== Ô TÌM KIẾM =====
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Tìm dịch vụ, phòng hoặc nhạc cụ...",
                        hintStyle: const TextStyle(color: Colors.white60),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFFFFD700)),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _filteredItems.clear();
                              _searchedProducts.clear();
                            });
                          },
                        )
                            : const Icon(Icons.tune, color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) async {
                        await _searchProducts(value); // 🔍 Gọi API tìm kiếm nhạc cụ
                        setState(() {
                          _filteredItems = _searchItems
                              .where((item) => item["name"]
                              .toString()
                              .toLowerCase()
                              .contains(value.toLowerCase()))
                              .toList();
                        });
                      },

                    ),

                    // ===== KẾT QUẢ TÌM KIẾM =====
                    if (_isSearching)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: CircularProgressIndicator(color: Colors.amberAccent)),
                      )
                    else if (_filteredItems.isNotEmpty)
                      _buildLocalSearchResults()
                    else if (_searchedProducts.isNotEmpty)
                        _buildProductResults()
                      else if (_searchController.text.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              "Không tìm thấy kết quả phù hợp.",
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),

                    const SizedBox(height: 20),
                    _buildChips(),
                    const SizedBox(height: 25),
                    OverlapCarousel(),
                    const SizedBox(height: 20),
                    _buildExploreSection(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );

    final screens = [
      homeContent,
      ServiceHistoryScreen(userData: widget.userData),
      ProfileScreen(userData: widget.userData),
      FeedbackFormScreen(userData: widget.userData), // ✅ Thêm form feedback trực tiếp
      const Center(child: Text("More", style: TextStyle(color: Colors.white))),
    ];


    return Scaffold(
      backgroundColor: Colors.black,
      body: screens[_selectedIndex],
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ====== HEADER ======
  Widget _buildHeader(String username, String avatarUrl) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            border: const Border(
              bottom: BorderSide(color: Color(0xFFFFD700), width: 2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 🌟 Logo có hiệu ứng shimmer vàng cam
                Shimmer.fromColors(
                  baseColor: Colors.orangeAccent.shade100,
                  highlightColor: Colors.yellowAccent,
                  period: const Duration(seconds: 3),
                  child: Image.asset(
                    'assets/images/logo5.png',
                    height: 85,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 14),

                // 🔥 Hàng chào + avatar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Text greeting
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hi, $username 👋",
                            style: GoogleFonts.lobster(
                              fontSize: 25,
                              color: const Color(0xFFFFD700),
                              shadows: [
                                const Shadow(
                                    color: Colors.black45,
                                    offset: Offset(1, 1),
                                    blurRadius: 2)
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Chào mừng đến với Zanee’s Music Studio!",
                            style: GoogleFonts.lobster(
                              fontSize: 17,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Avatar có viền sáng
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFFD700),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amberAccent.withOpacity(0.4),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 27,
                        backgroundColor: Colors.black.withOpacity(0.5),
                        backgroundImage: NetworkImage(avatarUrl),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildChips() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        _buildChip("Thuê Phòng Tập"),
        _buildChip("Thu Âm"),
        _buildChip("Làm Nhạc"),
        _buildChip("Thuê nhạc cụ"),
      ],
    ),
  );

  Widget _buildExploreSection() => Column(
    children: [
      Text("Khám Phá Dịch Vụ Nổi Bật",
          style: GoogleFonts.lobster(
            fontSize: 26,
            color: const Color(0xFFFFD700),
          )),
      const SizedBox(height: 20),
      GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1,
        children: [
          _buildServiceCard("Thuê Phòng Tập", "assets/images/room.jpg"),
          _buildServiceCard("Thuê Nhạc Cụ", "assets/images/instrument.jpg"),
          _buildServiceCard("Dịch Vụ Thu Âm", "assets/images/recording.jpg"),
          _buildServiceCard("Dịch Vụ Làm Nhạc", "assets/images/music.jpg"),
        ],
      ),
    ],
  );

  Widget _buildChip(String label) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD700), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(label,
            style: GoogleFonts.lobster(
                color: const Color(0xFFFFD700), fontSize: 15)),
      ),
    ),
  );

  Widget _buildServiceCard(String title, String imagePath) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        if (title == "Thuê Phòng Tập") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RoomListScreen(userData: widget.userData),
            ),
          );
        } else if (title == "Thuê Nhạc Cụ") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InstrumentListScreen(userData: widget.userData),
            ),
          );
        } else if (title == "Dịch Vụ Thu Âm") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RecordingFormScreen(
                userData: widget.userData, // ✅ truyền dữ liệu người dùng qua
              ),
            ),
          );
        } else if (title == "Dịch Vụ Làm Nhạc") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MusicRequestFormScreen(
                userData: widget.userData, // ✅ truyền dữ liệu người dùng qua
              ),
            ),
          );
        }
      },
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFD700), width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                imagePath,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lobster(
                    color: Colors.white,
                    fontSize: 17,
                    shadows: const [
                      Shadow(
                        color: Colors.black45,
                        offset: Offset(1, 1),
                        blurRadius: 2,
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ====== BOTTOM NAV ======
  Widget _buildBottomNav() => BottomNavigationBar(
    backgroundColor: Colors.black.withOpacity(0.85),
    currentIndex: _selectedIndex,
    type: BottomNavigationBarType.fixed,
    selectedItemColor: const Color(0xFFFFD700),
    unselectedItemColor: Colors.white54,
    showUnselectedLabels: true,
    selectedLabelStyle: GoogleFonts.lobster(fontSize: 14),
    unselectedLabelStyle: GoogleFonts.lobster(fontSize: 13),
    onTap: (index) {
      if (index == 4) {
        // 👉 Menu "More"
        _showMoreMenu();
      } else {
        // 👉 Các tab khác, bao gồm Inbox
        setState(() => _selectedIndex = index);
      }
    },
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
      BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: "Lịch sử đơn"),
      BottomNavigationBarItem(icon: Icon(Icons.people_alt), label: "Người dùng"),
      BottomNavigationBarItem(icon: Icon(Icons.mail_outline), label: "Inbox"),
      BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: "More"),
    ],
  );


  Widget _buildProductResults() => Container(
    margin: const EdgeInsets.only(top: 10),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.8),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.amber.withOpacity(0.5)),
    ),
    child: ListView.builder(
      shrinkWrap: true,
      itemCount: _searchedProducts.length,
      itemBuilder: (context, index) {
        final p = _searchedProducts[index];
        final imageUrl = p.imageUrl.startsWith("http")
            ? p.imageUrl
            : "http://10.0.2.2:5167${p.imageUrl}";

        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) =>
              const Icon(Icons.broken_image, color: Colors.white54),
            ),
          ),
          title: Text(p.name, style: const TextStyle(color: Colors.amber)),
          subtitle: Text(
            "${p.categoryName} - ${p.price} VNĐ",
            style: const TextStyle(color: Colors.white70),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(product: p),
              ),
            );
          },
        );
      },
    ),
  );

  Widget _buildLocalSearchResults() => Container(
    margin: const EdgeInsets.only(top: 10),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.8),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.amber.withOpacity(0.5)),
    ),
    child: ListView.builder(
      shrinkWrap: true,
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        return ListTile(
          leading: Icon(item["icon"], color: Colors.amber),
          title: Text(item["name"],
              style: const TextStyle(color: Colors.white)),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => item["page"]),
            );
            setState(() {
              _filteredItems.clear();
              _searchController.clear();
            });
          },
        );
      },
    ),
  );

  void _showMoreMenu() {
    showModalBottomSheet(
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 5,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10)),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month, color: Colors.amber),
              title: const Text("📅 Lịch Phòng",
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const RoomSchedulePage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.headphones, color: Colors.amber),
              title: const Text("🎧 Gói Thu Âm",
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const RecordingPackagesPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.music_note, color: Colors.amber),
              title: const Text("🎸 Danh Sách Nhạc Cụ",
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const InstrumentListPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.card_giftcard, color: Colors.amber),
              title: const Text("💳 Khuyến Mãi / Voucher",
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const VoucherPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline, color: Colors.amber),
              title: const Text("🧾 Chính Sách & Hỗ Trợ",
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const SupportPolicyPage()));
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}