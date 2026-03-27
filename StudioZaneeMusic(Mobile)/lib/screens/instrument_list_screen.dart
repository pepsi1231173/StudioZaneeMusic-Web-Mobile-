import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/instrument.dart';
import '../services/api_service.dart';
import '../services/signalr_service.dart'; // 🟢 Thêm import SignalR
import '../screens/instrument_invoice_screen.dart';
import '../screens/home_screen.dart';

class InstrumentListScreen extends StatefulWidget {
  final Map<String, dynamic> userData; // ✅ Thêm dòng này

  const InstrumentListScreen({Key? key, required this.userData}) : super(key: key);

  @override
  State<InstrumentListScreen> createState() => _InstrumentListScreenState();
}

class _InstrumentListScreenState extends State<InstrumentListScreen> {
  final ApiService apiService = ApiService();
  final SignalRService _signalR =
  SignalRService(hubUrl: "http://10.0.2.2:5167/instrumentHub"); // 🛰️ Hub nhạc cụ

  List<Instrument> instruments = [];
  List<Instrument> filteredInstruments = [];
  Set<int> selectedInstruments = {};
  bool isLoading = true;

  String? selectedCategory;
  List<Map<String, String>> categories = [];

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchInstruments();
    _initSignalR(); // 🛰️ realtime

    // ✅ Ưu tiên đổ dữ liệu từ userData trước
    nameController.text = widget.userData["fullName"] ?? '';
    emailController.text = widget.userData["email"] ?? '';
    phoneController.text = widget.userData["phoneNumber"] ?? '';

    // ✅ Nếu userData trống (ví dụ chưa login Google) thì fallback SharedPreferences
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        phoneController.text.isEmpty) {
      _loadUserProfile();
    }
  }


  // 🛰️ Khởi tạo SignalR để nhận realtime
  Future<void> _initSignalR() async {
    await _signalR.start(
      onRentalStatusChanged: (rentalId, status) async {
        print("📡 Realtime: Thuê nhạc cụ #$rentalId → $status");
        await fetchInstruments();
      },
      onInstrumentMaintenance: (ids) async {
        print("🔧 Nhạc cụ bảo trì thay đổi: $ids");
        await fetchInstruments();
      },
    );
  }

  @override
  void dispose() {
    _signalR.stop(); // 🛑 Dừng SignalR khi rời trang
    super.dispose();
  }

  // 🔹 Gọi API khi chọn ngày để đánh dấu nhạc cụ đã thuê
  Future<void> _onDateChanged(DateTime date) async {
    try {
      final instrumentsFromServer =
      await apiService.getInstrumentStatusByDate(date);
      setState(() {
        instruments = instrumentsFromServer;
        _filterByCategory(selectedCategory);
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi tải trạng thái: $e')));
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 🛡️ Chỉ load nếu các field hiện tại đang trống
      setState(() {
        if (nameController.text.isEmpty) {
          nameController.text = prefs.getString('user_fullname') ?? '';
        }
        if (emailController.text.isEmpty) {
          emailController.text = prefs.getString('user_email') ?? '';
        }
        if (phoneController.text.isEmpty) {
          phoneController.text = prefs.getString('user_phone') ?? '';
        }
      });
    } catch (e) {
      debugPrint("⚠️ Không thể tải thông tin người dùng: $e");
    }
  }


  Future<void> fetchCategories() async {
    try {
      final data = await apiService.getInstrumentCategoriesWithName();
      if (!mounted) return;
      setState(() {
        categories = [
          {"id": "", "name": "🎵 Tất cả"},
          ...data
        ];
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi tải loại nhạc cụ: $e')));
    }
  }

  Future<void> fetchInstruments() async {
    try {
      final data = await apiService.getInstruments();
      if (!mounted) return;
      setState(() {
        instruments = data;
        filteredInstruments = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi tải nhạc cụ: $e')));
    }
  }

  void _filterByCategory(String? categoryId) {
    setState(() {
      selectedCategory = categoryId;
      filteredInstruments = (categoryId == null || categoryId.isEmpty)
          ? instruments
          : instruments
          .where((i) => i.categoryId.toString() == categoryId)
          .toList();
    });
  }

  // 🚫 Không cho chọn nhạc cụ đã thuê hoặc bảo trì
  void _toggleSelect(int id) {
    final instrument = instruments.firstWhere((i) => i.id == id);
    if (instrument.isRented || instrument.isUnderMaintenance) return;
    setState(() {
      selectedInstruments.contains(id)
          ? selectedInstruments.remove(id)
          : selectedInstruments.add(id);
    });
  }

  Future<void> _rentSelectedInstruments() async {
    if (selectedInstruments.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Chưa chọn nhạc cụ nào')));
      return;
    }
    if (nameController.text.isEmpty ||
        phoneController.text.isEmpty ||
        selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')));
      return;
    }

    try {
      final data = {
        "CustomerName": nameController.text,
        "CustomerPhone": phoneController.text,
        "CustomerEmail": emailController.text,
        "RentalDate": selectedDate!.toIso8601String(),
        "SelectedInstruments": selectedInstruments.toList(),
      };

      final result = await apiService.createInstrumentRental(data);

      if (result != null && result["success"] == true) {
        final rentalId = result["rentalId"];
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InstrumentInvoiceScreen(
              rentalId: rentalId,
              userData: widget.userData, // ✅ Truyền đúng userData hiện tại
            ),
          ),
        );
        selectedInstruments.clear();
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Đặt thuê thất bại')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  String _imageFor(Instrument i) {
    if (i.img == null || i.img!.isEmpty) return '';
    return i.img!.startsWith('http')
        ? i.img!
        : 'http://10.0.2.2:5167${i.img}';
  }

  // 🎨 UI PHẦN DƯỚI GIỮ NGUYÊN — KHÔNG SỬA ĐỔI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/BACKROUND.jpg', fit: BoxFit.cover),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black87, Colors.black, Colors.black87],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildUserForm(context),
                const SizedBox(height: 16),
                Expanded(child: _buildInstrumentGrid()),
                _buildBottomButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    child: Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.amberAccent),
        ),
        const Expanded(
          child: Text(
            "🎸 Thuê Nhạc Cụ",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.amberAccent,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2),
          ),
        ),
        const SizedBox(width: 48),
      ],
    ),
  );

  Widget _buildUserForm(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.amber.withOpacity(0.4)),
    ),
    child: Column(
      children: [
        _buildTextField("Họ và tên", nameController),
        const SizedBox(height: 8),
        _buildTextField("Số điện thoại", phoneController,
            keyboardType: TextInputType.phone),
        const SizedBox(height: 8),
        _buildTextField("Email", emailController,
            keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 8),
        _buildDatePicker(context),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          dropdownColor: Colors.grey[900],
          decoration: InputDecoration(
            labelText: "🎶 Loại nhạc cụ",
            labelStyle: const TextStyle(color: Colors.amber),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          value: selectedCategory,
          items: categories
              .map((c) => DropdownMenuItem(
            value: c['id'],
            child: Text(c['name']!,
                style: const TextStyle(color: Colors.white)),
          ))
              .toList(),
          onChanged: _filterByCategory,
        ),
      ],
    ),
  );

  Widget _buildInstrumentGrid() => isLoading
      ? const Center(child: CircularProgressIndicator(color: Colors.amber))
      : GridView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.72,
    ),
    itemCount: filteredInstruments.length,
    itemBuilder: (context, index) {
      final instrument = filteredInstruments[index];
      final selected = selectedInstruments.contains(instrument.id);
      final isDisabled =
          instrument.isUnderMaintenance || instrument.isRented;

      return GestureDetector(
        onTap: () {
          if (!isDisabled) _toggleSelect(instrument.id);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? Colors.amberAccent : Colors.transparent,
              width: 2,
            ),
            color: Colors.white.withOpacity(0.08),
          ),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ColorFiltered(
                        colorFilter: isDisabled
                            ? const ColorFilter.mode(
                            Colors.grey, BlendMode.saturation)
                            : const ColorFilter.mode(
                            Colors.transparent, BlendMode.multiply),
                        child: Image.network(
                          _imageFor(instrument),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.music_note,
                            color: Colors.grey,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                    if (isDisabled)
                      Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          instrument.isUnderMaintenance
                              ? "ĐANG BẢO TRÌ"
                              : "ĐÃ THUÊ",
                          style: TextStyle(
                            color: instrument.isUnderMaintenance
                                ? Colors.orangeAccent
                                : Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                instrument.name ?? "Không rõ",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDisabled ? Colors.grey : Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                "${instrument.price.toStringAsFixed(0)} đ/ngày",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                  isDisabled ? Colors.grey : Colors.amberAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      );
    },
  );

  Widget _buildBottomButtons() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const HomeScreen(userData: {})),
          ),
          icon: const Icon(Icons.home, color: Colors.black),
          label: const Text("Về Trang Chủ",
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            padding:
            const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _rentSelectedInstruments,
          icon: const Icon(Icons.bolt, color: Colors.black),
          label: const Text("Thuê Ngay",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amberAccent,
            elevation: 12,
            padding:
            const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    ),
  );

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.amber),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 30)),
          builder: (context, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme:
              const ColorScheme.dark(primary: Colors.amber, onSurface: Colors.white),
            ),
            child: child!,
          ),
        );
        if (picked != null) {
          setState(() => selectedDate = picked);
          await _onDateChanged(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.amber),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.amber),
            const SizedBox(width: 10),
            Text(
              selectedDate == null
                  ? "Chọn ngày thuê"
                  : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
