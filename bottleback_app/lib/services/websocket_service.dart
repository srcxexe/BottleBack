import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  // --- FIX 1: เพิ่มตัวแปรสำหรับเก็บ Broadcast Stream ---
  Stream? _broadcastStream; 
  // ----------------------------------------------------
  
  // เปลี่ยนเป็นตัวแปร (ลบ final) เพื่อให้เปลี่ยนค่าได้
  String _serverUrl = 'ws://10.230.236.4:8765'; 

  bool isConnected = false;

  // --- FIX 1: เพิ่ม getter currentIp ---
  String get currentIp {
    try {
      final uri = Uri.parse(_serverUrl);
      return uri.host;
    } catch (_) {
      return _serverUrl;
    }
  }

  // --- FIX 2: เพิ่มเมธอด setServerIp ---\
  void setServerIp(String ip) {
    String cleanIp = ip.trim();
    if (cleanIp.isEmpty) return;

    // ถ้าไม่ได้ใส่ ws:// มา ให้เติมให้
    if (!cleanIp.startsWith('ws://')) {
      _serverUrl = 'ws://$cleanIp:8765';
    } else {
      _serverUrl = cleanIp;
    }
    print("🌐 Server IP updated to: $_serverUrl");
  }

  // --- FIX 3: connect() แบบไม่มี argument (ปรับปรุงส่วน stream) ---
  void connect() {
    try {
      // ถ้าเชื่อมต่ออยู่แล้ว ให้ตัดการเชื่อมต่อเก่าก่อน
      if (isConnected || _channel != null) {
        disconnect();
      }
      
      print("Connecting to: $_serverUrl");
      _channel = WebSocketChannel.connect(Uri.parse(_serverUrl));
      
      // --- FIX 2: สร้าง Broadcast Stream เพียงครั้งเดียวและเก็บไว้ ---
      _broadcastStream = _channel!.stream.asBroadcastStream();
      // -----------------------------------------------------------
      
      isConnected = true;
      print("✅ Connected to $_serverUrl");

      // ฟัง Stream เพื่อจัดการสถานะการเชื่อมต่อ (Optional) โดยใช้ Broadcast Stream ที่สร้างไว้
      _broadcastStream!.listen( 
        (event) {},
        onDone: () {
          print("❌ WebSocket connection closed");
          isConnected = false;
        },
        onError: (error) {
          print("🔥 WebSocket error: $error");
          isConnected = false;
        },
      );

    } catch (e) {
      print("🔥 Connection Error: $e");
      isConnected = false;
    }
  }

  void disconnect() {
    if (_channel != null) {
      _channel!.sink.close(status.goingAway);
      _channel = null;
    }
    // --- FIX 3: เคลียร์ Broadcast Stream ด้วย ---
    _broadcastStream = null;
    // ---------------------------------------
    isConnected = false;
  }

  // ส่งข้อความ String ธรรมดา (เช่น "GO", "END")
  void sendMessage(String message) {
    if (_channel != null && isConnected) {
      _channel!.sink.add(message);
      print("Sent: $message");
    } else {
      print("⚠️ Cannot send message. WebSocket not connected.");
    }
  }

  // ฟังก์ชันสำหรับหน้า Payout
  void sendPayoutCommand(double amount) {
    if (_channel != null && isConnected) {
      final message = jsonEncode({
        "action": "PAYOUT",
        "amount": amount,
        "timestamp": DateTime.now().toIso8601String(),
      });
      _channel!.sink.add(message);
      print("💸 Sent Payout Command: $amount");
    } else {
      print("⚠️ WebSocket not connected. Attempting to connect...");
      connect();
      // ลองส่งใหม่หลังจาก delay เล็กน้อย
      Future.delayed(const Duration(milliseconds: 500), () {
        if (isConnected && _channel != null) {
          final message = jsonEncode({
            "action": "PAYOUT",
            "amount": amount,
            "timestamp": DateTime.now().toIso8601String(),
          });
          _channel!.sink.add(message);
        }
      });
    }
  }

  // --- FIX 4: Getter 'stream' คืนค่า Broadcast Stream ที่ถูกเก็บไว้ ---
  Stream get stream {
    if (_broadcastStream != null) {
      return _broadcastStream!;
    }
    // Fallback เมื่อยังไม่มีการเชื่อมต่อ (Stream.empty เป็น Single-subscription)
    return const Stream.empty();
  }
}