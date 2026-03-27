import 'dart:async';
import 'package:signalr_core/signalr_core.dart';

typedef BookingCreatedHandler = void Function(Map<String, dynamic> booking);
typedef BookingStatusChangedHandler = void Function(
    int id,
    String roomId,
    String date,
    int startHour,
    int duration,
    String newStatus,
    );
typedef BookingDeletedHandler = void Function(
    int id,
    String roomId,
    String date,
    int startHour,
    int duration,
    );
typedef MaintenanceUpdatedHandler = void Function(List<String> maintenanceRooms);
typedef ReceiveTimeHandler = void Function(String now);

// 🪕 Thêm typedef riêng cho nhạc cụ
typedef RentalStatusChangedHandler = void Function(int rentalId, String status);
typedef InstrumentMaintenanceHandler = void Function(List<String> instrumentIds);

class SignalRService {
  final String hubUrl;
  final Future<String?> Function()? tokenProvider;
  HubConnection? _connection;
  bool _started = false;
  bool _isConnecting = false;

  SignalRService({required this.hubUrl, this.tokenProvider});

  Future<void> start({
    BookingCreatedHandler? onBookingCreated,
    BookingStatusChangedHandler? onBookingStatusChanged,
    BookingDeletedHandler? onBookingDeleted,
    MaintenanceUpdatedHandler? onMaintenanceUpdated,
    ReceiveTimeHandler? onReceiveTime,

    // 🎸 Cho thuê nhạc cụ
    RentalStatusChangedHandler? onRentalStatusChanged,
    InstrumentMaintenanceHandler? onInstrumentMaintenance,
  }) async {
    if (_isConnecting || _started) {
      print("⚠️ [SignalR] Already connecting or started.");
      return;
    }

    _isConnecting = true;
    print("🛰️ [SignalR] Connecting to $hubUrl ...");

    final options = HttpConnectionOptions(
      transport: HttpTransportType.webSockets,
      skipNegotiation: false,
      logging: (level, message) => print("🛰️ [SignalR] $message"),
      accessTokenFactory: tokenProvider != null ? () async => await tokenProvider!() : null,
    );

    _connection = HubConnectionBuilder()
        .withUrl(hubUrl, options)
        .withAutomaticReconnect([0, 2, 5, 10])
        .build();

    // 🎯 Booking events (cũ)
    _connection!.on('BookingCreated', (args) {
      if (args != null && args.isNotEmpty) {
        onBookingCreated?.call(Map<String, dynamic>.from(args[0]));
      }
    });

    _connection!.on('BookingStatusChanged', (args) {
      if (args != null && args.length >= 6) {
        onBookingStatusChanged?.call(
          int.tryParse(args[0].toString()) ?? 0,
          args[1].toString(),
          args[2].toString(),
          int.tryParse(args[3].toString()) ?? 0,
          int.tryParse(args[4].toString()) ?? 1,
          args[5].toString(),
        );
      }
    });

    _connection!.on('BookingDeleted', (args) {
      if (args != null && args.length >= 5) {
        onBookingDeleted?.call(
          int.tryParse(args[0].toString()) ?? 0,
          args[1].toString(),
          args[2].toString(),
          int.tryParse(args[3].toString()) ?? 0,
          int.tryParse(args[4].toString()) ?? 1,
        );
      }
    });

    _connection!.on('MaintenanceUpdated', (args) {
      if (args != null && args.isNotEmpty) {
        final raw = args[0];
        final rooms = raw is List
            ? raw.map((e) => e.toString()).toList()
            : [raw.toString()];
        onMaintenanceUpdated?.call(rooms);
      }
    });

    _connection!.on('ReceiveTime', (args) {
      if (args != null && args.isNotEmpty) {
        onReceiveTime?.call(args[0].toString());
      }
    });

    // 🪕 Thêm event cho InstrumentRental
    _connection!.on('RentalStatusChanged', (args) {
      if (args != null && args.length >= 2) {
        final rentalId = int.tryParse(args[0].toString()) ?? 0;
        final status = args[1].toString();
        print("🎸 [SignalR] Rental #$rentalId → $status");
        onRentalStatusChanged?.call(rentalId, status);
      }
    });

    _connection!.on('InstrumentMaintenanceUpdated', (args) {
      if (args != null && args.isNotEmpty) {
        final raw = args[0];
        final ids = raw is List
            ? raw.map((e) => e.toString()).toList()
            : [raw.toString()];
        print("🛠 [SignalR] Instrument Maintenance: $ids");
        onInstrumentMaintenance?.call(ids);
      }
    });

    // 💬 Lifecycle
    _connection!.onreconnecting((error) {
      print("⏳ [SignalR] Reconnecting... $error");
    });

    _connection!.onreconnected((connectionId) {
      print("🔁 [SignalR] Reconnected! $connectionId");
    });

    _connection!.onclose((error) async {
      print("🛑 [SignalR] Closed: $error");
      _started = false;
      _isConnecting = false;
      await _retryConnect(
        onBookingCreated: onBookingCreated,
        onBookingStatusChanged: onBookingStatusChanged,
        onBookingDeleted: onBookingDeleted,
        onMaintenanceUpdated: onMaintenanceUpdated,
        onReceiveTime: onReceiveTime,
        onRentalStatusChanged: onRentalStatusChanged,
        onInstrumentMaintenance: onInstrumentMaintenance,
      );
    });

    // 🚀 Start safely
    try {
      await _connection!.start();
      _started = true;
      print("✅ [SignalR] Connected!");
    } catch (e) {
      print("🚨 [SignalR] Failed to connect: $e");
      await _safeStop();
      await _retryConnect(
        onBookingCreated: onBookingCreated,
        onBookingStatusChanged: onBookingStatusChanged,
        onBookingDeleted: onBookingDeleted,
        onMaintenanceUpdated: onMaintenanceUpdated,
        onReceiveTime: onReceiveTime,
        onRentalStatusChanged: onRentalStatusChanged,
        onInstrumentMaintenance: onInstrumentMaintenance,
      );
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> _retryConnect({
    BookingCreatedHandler? onBookingCreated,
    BookingStatusChangedHandler? onBookingStatusChanged,
    BookingDeletedHandler? onBookingDeleted,
    MaintenanceUpdatedHandler? onMaintenanceUpdated,
    ReceiveTimeHandler? onReceiveTime,
    RentalStatusChangedHandler? onRentalStatusChanged,
    InstrumentMaintenanceHandler? onInstrumentMaintenance,
  }) async {
    for (int i = 1; i <= 3; i++) {
      print("🔌 [SignalR] Retry $i...");
      await Future.delayed(Duration(seconds: 3 * i));
      try {
        await _safeStop();
        await start(
          onBookingCreated: onBookingCreated,
          onBookingStatusChanged: onBookingStatusChanged,
          onBookingDeleted: onBookingDeleted,
          onMaintenanceUpdated: onMaintenanceUpdated,
          onReceiveTime: onReceiveTime,
          onRentalStatusChanged: onRentalStatusChanged,
          onInstrumentMaintenance: onInstrumentMaintenance,
        );
        if (_started) {
          print("✅ [SignalR] Reconnected after $i tries!");
          return;
        }
      } catch (e) {
        print("❌ [SignalR] Attempt $i failed: $e");
      }
    }
  }

  Future<void> _safeStop() async {
    try {
      if (_connection != null && _connection!.state != HubConnectionState.disconnected) {
        print("🧹 [SignalR] Stopping old connection...");
        await _connection!.stop();
      }
    } catch (e) {
      print("⚠️ [SignalR] Stop error: $e");
    } finally {
      _started = false;
      _isConnecting = false;
    }
  }

  Future<void> stop() async => await _safeStop();
  bool get isConnected => _connection?.state == HubConnectionState.connected;
}
