// Stub para plataformas não-Web: fornece window.navigator.mediaDevices.enumerateDevices()

class MediaDevicesCompat {
  Future<List<dynamic>> enumerateDevices() async => <dynamic>[];
}

class NavigatorCompat {
  final MediaDevicesCompat mediaDevices = MediaDevicesCompat();
}

class WindowCompat {
  final NavigatorCompat navigator = NavigatorCompat();
}

// Exponha um 'window' público com tipo público
final WindowCompat window = WindowCompat();
