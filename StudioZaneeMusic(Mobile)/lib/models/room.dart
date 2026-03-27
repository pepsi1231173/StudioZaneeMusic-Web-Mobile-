class Room {
  final int id;
  final String roomName;
  final double price;

  Room({required this.id, required this.roomName, required this.price});

  factory Room.fromJson(Map<String, dynamic> json) => Room(
    id: json['id'] ?? 0,
    roomName: json['roomName'] ?? '',
    price: (json['price'] ?? 0).toDouble(),
  );
}
