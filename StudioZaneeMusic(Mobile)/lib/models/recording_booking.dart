class RecordingBooking {
  int? id;
  String customerName;
  String customerEmail;
  String customerPhone;
  String recordingPackage;
  int? price;
  String recordingDate; // yyyy-MM-dd
  String recordingTime; // HH:mm:ss
  int duration;
  String? status;

  RecordingBooking({
    this.id,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.recordingPackage,
    this.price,
    required this.recordingDate,
    required this.recordingTime,
    required this.duration,
    this.status,
  });

  Map<String, dynamic> toJson() => {
    'customerName': customerName,
    'customerEmail': customerEmail,
    'customerPhone': customerPhone,
    'recordingPackage': recordingPackage,
    'price': price ?? 0,
    'recordingDate': recordingDate,
    'recordingTime': recordingTime,
    'duration': duration,
    'status': status ?? "pending",
  };

  factory RecordingBooking.fromJson(Map<String, dynamic> json) =>
      RecordingBooking(
        id: json['id'],
        customerName: json['customerName'],
        customerEmail: json['customerEmail'],
        customerPhone: json['customerPhone'],
        recordingPackage: json['recordingPackage'],
        price: json['price'],
        recordingDate: json['recordingDate'],
        recordingTime: json['recordingTime'],
        duration: json['duration'],
        status: json['status'],
      );
}
