import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VoucherPage extends StatelessWidget {
  const VoucherPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vouchers = [
      {"title": "Giảm 10% khi đặt phòng 3 giờ", "code": "STUDIO10"},
      {"title": "Giảm 50k cho thuê nhạc cụ", "code": "MUSIC50"},
      {"title": "Thu âm 2 tặng 1 giờ", "code": "FREEREC"},
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("💳 Khuyến Mãi / Voucher",
            style: GoogleFonts.lobster(color: Colors.amberAccent, fontSize: 24)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: vouchers.map((v) {
          return Card(
            color: Colors.grey[900],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.local_offer, color: Colors.amber),
              title: Text(v["title"]!,
                  style: GoogleFonts.lato(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text("Mã: ${v["code"]}",
                  style: GoogleFonts.lato(color: Colors.amberAccent)),
              trailing: const Icon(Icons.copy, color: Colors.white54),
            ),
          );
        }).toList(),
      ),
    );
  }
}
