import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RecordingPackagesPage extends StatelessWidget {
  const RecordingPackagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final packages = [
      {"name": "Gói Basic", "price": "200.000đ/giờ"},
      {"name": "Gói Pro", "price": "350.000đ/giờ"},
      {"name": "Gói Premium", "price": "500.000đ/giờ"},
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("🎧 Gói Thu Âm",
            style: GoogleFonts.lobster(color: Colors.amberAccent, fontSize: 24)),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: packages.length,
        itemBuilder: (context, index) {
          final pkg = packages[index];
          return Card(
            color: Colors.grey[900],
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              leading: const Icon(Icons.music_video, color: Colors.amber),
              title: Text(pkg["name"]!,
                  style:
                  GoogleFonts.lato(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(pkg["price"]!,
                  style: GoogleFonts.lato(color: Colors.amberAccent)),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 18),
            ),
          );
        },
      ),
    );
  }
}
