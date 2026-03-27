class Booking {
  final int id;
  final String roomName;
  final String status;
  final String startTime;
  final String endTime;
  final String customerName;

  Booking({
    required this.id,
    required this.roomName,
    required this.status,
    required this.startTime,
    required this.endTime,
    required this.customerName,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      roomName: json['roomId'] ?? json['roomName'] ?? '',
      status: json['status'] ?? 'unknown',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      customerName: json['customerName'] ?? '',
    );
  }
}
