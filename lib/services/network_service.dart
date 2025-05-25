import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkService {
  Future<bool> hasInternetConnection() async {
    try {
      final result = await Connectivity().checkConnectivity();

      final ConnectivityResult connectivity = result as ConnectivityResult;
      if (connectivity == ConnectivityResult.none) return false;

      final lookup = await InternetAddress.lookup('google.com');
      return lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
