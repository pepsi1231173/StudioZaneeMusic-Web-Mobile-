import 'dart:ui';
import 'package:flutter/material.dart';

class MusicInvoiceScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const MusicInvoiceScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🎸 Hình nền
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/BACKROUND.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Lớp phủ
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.7),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Nội dung
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.amberAccent.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '🎼 Dịch Vụ Làm Nhạc 🎶',
                        style: TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Cảm ơn bạn đã gửi yêu cầu!\nDưới đây là thông tin bạn đã nhập:',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 25),

                      _buildInfo('🎵 Thể loại nhạc', data['musicGenre']),
                      _buildInfo('📝 Mô tả yêu cầu', data['musicDescription']),
                      _buildInfo('👤 Họ tên khách hàng', data['customerName']),
                      _buildInfo('📧 Email', data['customerEmail']),
                      _buildInfo('📱 Số điện thoại', data['customerPhone']),
                      const SizedBox(height: 35),

                      SizedBox(
                        width: 230,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amberAccent.withOpacity(0.9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            elevation: 4,
                          ),
                          onPressed: () {
                            Navigator.pop(context); // ✅ Quay về trang trước
                          },
                          child: const Text(
                            '⬅️ Quay lại',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
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
        ],
      ),
    );
  }

  Widget _buildInfo(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.amberAccent,
                fontWeight: FontWeight.w600,
                fontSize: 15.5,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value?.isNotEmpty == true ? value! : '—',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.3,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
