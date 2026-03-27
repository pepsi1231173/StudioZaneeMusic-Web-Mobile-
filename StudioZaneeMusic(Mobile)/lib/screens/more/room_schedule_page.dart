import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RoomSchedulePage extends StatelessWidget {
  const RoomSchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          "📅 Lịch Phòng",
          style: GoogleFonts.lobster(color: Colors.amberAccent, fontSize: 24),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          "Hiển thị lịch trống và đã đặt của các phòng thu âm 🎧",
          textAlign: TextAlign.center,
          style: GoogleFonts.lato(color: Colors.white70, fontSize: 16),
        ),
      ),
    );
  }
}
