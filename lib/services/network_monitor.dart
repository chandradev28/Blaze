import 'package:connectivity_plus/connectivity_plus.dart';

enum NetworkTransport {
  unknown,
  offline,
  mobile,
  wifi,
  ethernet,
  vpn,
  bluetooth,
  other,
}

class NetworkSnapshot {
  const NetworkSnapshot(this.transport);

  const NetworkSnapshot.unknown() : transport = NetworkTransport.unknown;

  final NetworkTransport transport;

  bool get isConnected => transport != NetworkTransport.offline;

  String get label {
    switch (transport) {
      case NetworkTransport.mobile:
        return 'MOBILE DATA';
      case NetworkTransport.wifi:
        return 'WI-FI / HOTSPOT';
      case NetworkTransport.ethernet:
        return 'ETHERNET';
      case NetworkTransport.vpn:
        return 'VPN';
      case NetworkTransport.bluetooth:
        return 'BLUETOOTH';
      case NetworkTransport.offline:
        return 'OFFLINE';
      case NetworkTransport.other:
        return 'CONNECTED';
      case NetworkTransport.unknown:
        return 'CHECKING NETWORK';
    }
  }

  static NetworkSnapshot fromConnectivity(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.mobile:
        return const NetworkSnapshot(NetworkTransport.mobile);
      case ConnectivityResult.wifi:
        return const NetworkSnapshot(NetworkTransport.wifi);
      case ConnectivityResult.ethernet:
        return const NetworkSnapshot(NetworkTransport.ethernet);
      case ConnectivityResult.vpn:
        return const NetworkSnapshot(NetworkTransport.vpn);
      case ConnectivityResult.bluetooth:
        return const NetworkSnapshot(NetworkTransport.bluetooth);
      case ConnectivityResult.none:
        return const NetworkSnapshot(NetworkTransport.offline);
      case ConnectivityResult.other:
        return const NetworkSnapshot(NetworkTransport.other);
    }
  }
}

abstract class NetworkMonitor {
  Future<NetworkSnapshot> check();

  Stream<NetworkSnapshot> get changes;
}

class ConnectivityNetworkMonitor implements NetworkMonitor {
  ConnectivityNetworkMonitor({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<NetworkSnapshot> check() async {
    final result = await _connectivity.checkConnectivity();
    return NetworkSnapshot.fromConnectivity(result);
  }

  @override
  Stream<NetworkSnapshot> get changes => _connectivity.onConnectivityChanged
      .map(NetworkSnapshot.fromConnectivity)
      .distinct((previous, next) => previous.transport == next.transport);
}
