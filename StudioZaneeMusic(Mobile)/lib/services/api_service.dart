import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/booking.dart';
import '../models/room.dart';
import '../models/instrument.dart';
import '../models/recording_booking.dart';
import '../models/music_request.dart';
import '../models/product.dart';
import '../models/feedback_model.dart';


class ApiService {
  static const String baseUrl = "http://10.0.2.2:5167/api"; // ⚙️ Localhost Android Emulator

  // ===========================================================
  // 🔹 AUTH
  // ===========================================================
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/AuthApi/Login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data["token"] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", data["token"]);
      return data;
    } else {
      throw Exception(data["message"] ?? "❌ Đăng nhập thất bại");
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/AuthApi/Register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"name": name, "email": email, "password": password}),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("❌ Đăng ký thất bại (${response.statusCode})");
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  // ✅ Header helper
  Future<Map<String, String>> getHeaders({bool withAuth = true}) async {
    final headers = {"Content-Type": "application/json"};
    if (withAuth) {
      final token = await getToken();
      if (token != null) headers["Authorization"] = "Bearer $token";
    }
    return headers;
  }

  // ===========================================================
  // 🔹 BOOKING
  // ===========================================================
  Future<List<Booking>> getBookings() async {
    final response = await http.get(Uri.parse("$baseUrl/BookingApi"));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Booking.fromJson(json)).toList();
    } else {
      throw Exception("❌ Lỗi lấy danh sách booking (${response.statusCode})");
    }
  }

  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> bookingData) async {
    final headers = await getHeaders();
    final url = Uri.parse("$baseUrl/InvoiceApi/Create");

    final response = await http.post(url, headers: headers, body: jsonEncode(bookingData));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception("❌ Lỗi đặt phòng: ${error['message'] ?? response.statusCode}");
    }
  }

  Future<Map<String, dynamic>> updateBookingStatus(int id, String status) async {
    final headers = await getHeaders();
    final response = await http.put(
      Uri.parse("$baseUrl/BookingApi/$id"),
      headers: headers,
      body: jsonEncode({"status": status}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("❌ Cập nhật trạng thái booking thất bại (${response.statusCode})");
    }
  }

  Future<bool> deleteBooking(int id) async {
    final headers = await getHeaders();
    final response = await http.delete(Uri.parse("$baseUrl/BookingApi/$id"), headers: headers);
    return response.statusCode == 204;
  }

  // ===========================================================
  // 🔹 ROOM
  // ===========================================================
  Future<List<Room>> getRooms() async {
    final headers = await getHeaders();
    final response = await http.get(Uri.parse("$baseUrl/RoomApi"), headers: headers);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Room.fromJson(json)).toList();
    } else {
      throw Exception("❌ Lỗi lấy danh sách phòng");
    }
  }

  // ===========================================================
  // 🔹 MAINTENANCE
  // ===========================================================
  Future<List<dynamic>> getMaintenanceList() async {
    final headers = await getHeaders();
    final response = await http.get(Uri.parse("$baseUrl/MaintenanceApi"), headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("❌ Lỗi lấy danh sách bảo trì");
    }
  }

  Future<Map<String, dynamic>> createMaintenance({
    required String roomId,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    final headers = await getHeaders();
    final response = await http.post(
      Uri.parse("$baseUrl/MaintenanceApi"),
      headers: headers,
      body: jsonEncode({
        "roomId": roomId,
        "startDate": startDate.toIso8601String(),
        "endDate": endDate.toIso8601String(),
        "reason": reason,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("❌ Gửi yêu cầu bảo trì thất bại (${response.statusCode})");
    }
  }

  Future<bool> deleteMaintenance(int id) async {
    final headers = await getHeaders();
    final response = await http.delete(Uri.parse("$baseUrl/MaintenanceApi/$id"), headers: headers);
    return response.statusCode == 204;
  }

  // ===========================================================
  // 🔹 ROOM SCHEDULE
  // ===========================================================
  Future<List<dynamic>> getRoomSchedule(String roomId) async {
    final response = await http.get(Uri.parse("$baseUrl/BookingApi/room/$roomId"));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("❌ Lỗi lấy lịch phòng ($roomId): ${response.statusCode}");
    }
  }

  // ===========================================================
  // 🔹 PROFILE
  // ===========================================================
  Future<Map<String, dynamic>> getProfile() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/UserApi/Profile"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("❌ Lỗi lấy thông tin người dùng");
    }
  }

  // ===========================================================
  // 🔹 SERVICE HISTORY
  // ===========================================================
  Future<Map<String, dynamic>> getServiceHistory(String email) async {
    final headers = await getHeaders(withAuth: false);
    final url = Uri.parse("$baseUrl/ServiceHistoryApi/$email");

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("❌ Lỗi lấy lịch sử dịch vụ (${response.statusCode})");
    }
  }
}

// ===========================================================
// 🔹 PRODUCT + INSTRUMENT + MUSIC REQUEST EXTENSION
// ===========================================================
extension ProductApi on ApiService {
  // 🔹 Lấy tất cả sản phẩm
  Future<List<Product>> getProducts() async {
    final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/ProductsApi"));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception("❌ Lỗi lấy danh sách nhạc cụ (${response.statusCode})");
    }
  }

  // 🔹 Lấy sản phẩm chi tiết theo ID
  Future<Product> getProductById(int id) async {
    final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/ProductsApi/$id"));
    if (response.statusCode == 200) {
      return Product.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("❌ Không tìm thấy nhạc cụ #$id");
    }
  }

  // 🔹 Lấy sản phẩm theo loại
  Future<List<Product>> getProductsByCategory(int categoryId) async {
    final response = await http.get(
      Uri.parse("${ApiService.baseUrl}/ProductsApi/by-category/$categoryId"),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception(
          "❌ Không có nhạc cụ thuộc loại này (${response.statusCode})");
    }
  }

  // 🔹 Tìm sản phẩm theo tên
  Future<List<Product>> getProductsByName(String keyword) async {
    final response = await http.get(
      Uri.parse("${ApiService.baseUrl}/ProductsApi/by-name/$keyword"),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception("❌ Lỗi tìm kiếm nhạc cụ (${response.statusCode})");
    }
  }

  // ✅ Lấy danh sách nhạc cụ
  Future<List<Instrument>> getInstruments() async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse("${ApiService.baseUrl}/ProductsApi"),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) {
        final map = Map<String, dynamic>.from(e);
        // 🟢 Ghép đúng URL ảnh
        map['imageUrl'] = 'http://10.0.2.2:5167${map['imageUrl']}';
        return Instrument.fromJson(map);
      }).toList();
    } else {
      throw Exception('❌ Failed to load instruments (status ${response.statusCode})');
    }
  }



  Future<Map<String, dynamic>?> createInstrumentRental(Map<String, dynamic> data) async {
    final url = Uri.parse('${ApiService.baseUrl}/InstrumentInvoiceApi/create');

    final body = {
        "CustomerName": data["CustomerName"],
        "CustomerPhone": data["CustomerPhone"],
        "CustomerEmail": data["CustomerEmail"],
        "RentalDate": data["RentalDate"],
        "SelectedInstruments": data["SelectedInstruments"].toList(), // ✅ CHỖ NÀY
    };


    print("📤 Gửi dữ liệu lên API: $body");

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final json = jsonDecode(response.body);
      print("✅ API success: $json");
      return json;
    } else {
      print("❌ API Error ${response.statusCode}: ${response.body}");
      return null;
    }
  }



  Future<Map<String, dynamic>?> getInstrumentInvoiceById(int rentalId) async {
    final url = Uri.parse('${ApiService.baseUrl}/InstrumentInvoiceApi/$rentalId');
    final headers = await getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("❌ Lỗi lấy hóa đơn thuê nhạc cụ #$rentalId: ${response.body}");
      return null;
    }
  }



  // ✅ Lấy danh sách loại nhạc cụ
  Future<List<Map<String, String>>> getInstrumentCategoriesWithName() async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/CategoriesApi'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data
          .map((e) => {'id': e['id'].toString(), 'name': e['name'].toString()})
          .toList();
    } else {
      throw Exception('❌ Failed to load categories');
    }
  }

  // ✅ Booking phòng thu âm
  Future<Map<String, dynamic>?> createRecordingBooking(
      Map<String, dynamic> bookingData) async {
    try {
      final headers = await getHeaders();
      final res = await http.post(
        Uri.parse("${ApiService.baseUrl}/RecordingApi"),
        headers: headers,
        body: jsonEncode(bookingData),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body);
      } else {
        print("❌ Lỗi khi tạo booking: ${res.statusCode} - ${res.body}");
        return null;
      }
    } catch (e) {
      print("❌ Lỗi kết nối: $e");
      return null;
    }
  }
  // ✅ Gửi yêu cầu làm nhạc (Music Request)
  Future<bool> createMusicRequest(MusicRequest request) async {
    try {
      final headers = await getHeaders();
      final res = await http.post(
        Uri.parse("${ApiService.baseUrl}/MusicRequestApi"),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return true;
      } else {
        print("❌ Lỗi khi gửi yêu cầu làm nhạc: ${res.statusCode} - ${res.body}");
        return false;
      }
    } catch (e) {
      print("❌ Lỗi kết nối khi gửi yêu cầu làm nhạc: $e");
      return false;
    }
  }
// ---------------------- FEEDBACK ----------------------
  /// ✅ Gửi feedback từ người dùng lên server
  Future<bool> sendFeedback(Map<String, dynamic> feedbackData) async {
    try {
      final api = ApiService();

      final res = await http.post(
        Uri.parse("${ApiService.baseUrl}/FeedbackApi"),
        headers: await api.getHeaders(), // ✅ gọi qua instance
        body: jsonEncode(feedbackData),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("✅ Gửi feedback thành công!");
        return true;
      } else {
        print("❌ Lỗi khi gửi feedback: ${res.statusCode} - ${res.body}");
        return false;
      }
    } catch (e) {
      print("🚨 Lỗi kết nối khi gửi feedback: $e");
      return false;
    }
  }

  /// ✅ Lấy danh sách feedback (cho admin)
  Future<List<FeedbackModel>> getAllFeedbacks() async {
    try {
      final api = ApiService();

      final res = await http.get(
        Uri.parse("${ApiService.baseUrl}/FeedbackApi"),
        headers: await api.getHeaders(), // ✅
      );

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => FeedbackModel.fromJson(e)).toList();
      } else {
        print("❌ Lỗi khi tải danh sách feedback: ${res.statusCode}");
        return [];
      }
    } catch (e) {
      print("🚨 Lỗi kết nối khi lấy feedback: $e");
      return [];
    }
  }
  Future<List<Instrument>> getInstrumentStatusByDate(DateTime date) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/InstrumentRentalsApi/status?date=${date.toIso8601String()}'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => Instrument.fromJson(e)).toList();
    } else {
      throw Exception('Không thể tải trạng thái nhạc cụ');
    }
  }

}


