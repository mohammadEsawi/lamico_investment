import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/api_config.dart';

class SocketService {
  static io.Socket? _socket;

  static void connect(String token) {
    _socket = io.io(ApiConfig.socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'auth': {'token': token},
    });
    _socket!.connect();
  }

  static void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  static void joinGroup(String groupId) =>
      _socket?.emit('join_group', groupId);

  static void sendMessage(Map<String, dynamic> data) =>
      _socket?.emit('send_message', data);

  static void onNewMessage(Function(dynamic) handler) =>
      _socket?.on('new_message', handler);

  static void onTyping(Function(dynamic) handler) =>
      _socket?.on('typing', handler);

  static void emitTyping(String groupId) =>
      _socket?.emit('typing', groupId);

  static void emitStopTyping(String groupId) =>
      _socket?.emit('stop_typing', groupId);

  static bool get isConnected => _socket?.connected ?? false;
}
