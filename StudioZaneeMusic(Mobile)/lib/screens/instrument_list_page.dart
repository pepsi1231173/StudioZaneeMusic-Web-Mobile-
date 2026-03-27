import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import 'product_detail_screen.dart';

class InstrumentListPage extends StatefulWidget {
  final String? initialKeyword; // 🔍 Nhận từ trang tìm kiếm

  const InstrumentListPage({super.key, this.initialKeyword});

  @override
  State<InstrumentListPage> createState() => _InstrumentListPageState();
}

class _InstrumentListPageState extends State<InstrumentListPage> {
  List<Product> instruments = [];
  bool isLoading = false;
  int? selectedCategoryId;

  static const String baseUrl = "http://10.0.2.2:5167/api/ProductsApi";

  // 🎵 Danh sách loại nhạc cụ (phù hợp API CategoryId)
  final List<Map<String, dynamic>> categories = [
    {"id": 3, "name": "🎸 Guitar"},
    {"id": 9, "name": "🥁 Trống (Drums)"},
    {"id": 5, "name": "🔊 Amplifier"},
    {"id": 6, "name": "🎚 Mixer"},
    {"id": 4, "name": "🎧 Audio Interface"},
    {"id": 7, "name": "🎤 In-Ear Monitoring"},
    {"id": 10, "name": "🎻 Violin"},
  ];

  // 🧠 Gọi API lấy danh sách theo CategoryId
  Future<void> fetchInstruments(int categoryId) async {
    setState(() => isLoading = true);
    try {
      final url = Uri.parse("$baseUrl/by-category/$categoryId");
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        setState(() {
          instruments = data.map((json) => Product.fromJson(json)).toList();
        });
      } else {
        setState(() => instruments = []);
        debugPrint("⚠️ Không có nhạc cụ thuộc loại này (${res.statusCode})");
      }
    } catch (e) {
      debugPrint("❌ Lỗi tải nhạc cụ: $e");
      setState(() => instruments = []);
    } finally {
      setState(() => isLoading = false);
    }
  }

  // 🔍 Tìm nhạc cụ theo tên hoặc loại
  Future<void> searchInstrumentByName(String keyword) async {
    if (keyword.trim().isEmpty) return;
    setState(() => isLoading = true);

    try {
      final url = Uri.parse("$baseUrl/by-name/$keyword");
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        setState(() {
          instruments = data.map((json) => Product.fromJson(json)).toList();
        });
      } else {
        setState(() => instruments = []);
      }
    } catch (e) {
      debugPrint("❌ Lỗi tìm kiếm: $e");
      setState(() => instruments = []);
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialKeyword != null && widget.initialKeyword!.isNotEmpty) {
      searchInstrumentByName(widget.initialKeyword!);
    }
  }

  // 🌀 Kéo để refresh
  Future<void> _refreshData() async {
    if (selectedCategoryId != null) {
      await fetchInstruments(selectedCategoryId!);
    } else if (widget.initialKeyword != null &&
        widget.initialKeyword!.isNotEmpty) {
      await searchInstrumentByName(widget.initialKeyword!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.initialKeyword != null && widget.initialKeyword!.isNotEmpty
              ? "Kết quả: ${widget.initialKeyword}"
              : "🎶 Danh Sách Nhạc Cụ",
          style: const TextStyle(color: Colors.amberAccent),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),

          // 🔽 Dropdown chọn loại nhạc cụ
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButtonFormField<int>(
              value: selectedCategoryId,
              dropdownColor: Colors.grey[900],
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.black54,
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                labelText: "Chọn loại nhạc cụ",
                labelStyle: const TextStyle(color: Colors.amberAccent),
              ),
              items: categories.map((cat) {
                return DropdownMenuItem<int>(
                  value: cat["id"],
                  child: Text(cat["name"],
                      style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedCategoryId = value;
                    instruments = [];
                  });
                  fetchInstruments(value);
                }
              },
            ),
          ),

          const SizedBox(height: 10),

          // 🔄 Danh sách nhạc cụ
          Expanded(
            child: isLoading
                ? const Center(
              child: CircularProgressIndicator(color: Colors.amberAccent),
            )
                : RefreshIndicator(
              onRefresh: _refreshData,
              color: Colors.amberAccent,
              child: instruments.isEmpty
                  ? const Center(
                child: Text(
                  "Không tìm thấy nhạc cụ nào.",
                  style: TextStyle(color: Colors.white70),
                ),
              )
                  : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: instruments.length,
                itemBuilder: (context, index) {
                  final p = instruments[index];
                  final imageUrl = p.imageUrl.startsWith("http")
                      ? p.imageUrl
                      : "http://10.0.2.2:5167${p.imageUrl}";

                  return Card(
                    color: Colors.grey[900],
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) =>
                          const Icon(Icons.broken_image,
                              color: Colors.white54),
                        ),
                      ),
                      title: Text(
                        p.name,
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        "${p.categoryName} - ${p.price} VNĐ",
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                      trailing: const Icon(Icons.chevron_right,
                          color: Colors.white54),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProductDetailScreen(product: p),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
