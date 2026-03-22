import 'dart:io';

class NetworkUtils {
  static Future<String?> getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (_isPrivateIp(addr.address)) return addr.address;
        }
      }
    } catch (_) {}
    return null;
  }

  static bool _isPrivateIp(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    final a = int.tryParse(parts[0]);
    final b = int.tryParse(parts[1]);
    if (a == null || b == null) return false;
    if (a == 10) return true;
    if (a == 192 && b == 168) return true;
    if (a == 172 && b >= 16 && b <= 31) return true;
    return false;
  }

  static bool isSameSubnet(String a, String b) {
    final p1 = a.split('.');
    final p2 = b.split('.');
    return p1.length == 4 &&
        p2.length == 4 &&
        p1[0] == p2[0] &&
        p1[1] == p2[1] &&
        p1[2] == p2[2];
  }
}
