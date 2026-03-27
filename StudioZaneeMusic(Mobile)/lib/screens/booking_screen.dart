import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/booking.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final ApiService api = ApiService();
  late Future<List<Booking>> futureBookings;

  @override
  void initState() {
    super.initState();
    futureBookings =api.getBookings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Danh sách đặt phòng")),
      body: FutureBuilder<List<Booking>>(
        future: futureBookings,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Chưa có đơn đặt phòng nào"));
          }

          final bookings = snapshot.data!;
          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final b = bookings[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text("Phòng: ${b.roomName}"),
                  subtitle: Text(
                      "Từ ${b.startTime} đến ${b.endTime}\nTrạng thái: ${b.status}"),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
