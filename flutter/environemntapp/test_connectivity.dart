import 'package:connectivity_plus/connectivity_plus.dart';

void main() async {
  print('Checking connectivity...');
  try {
    final result = await Connectivity().checkConnectivity().timeout(Duration(seconds: 3));
    print('Result: $result');
  } catch (e) {
    print('Error: $e');
  }
}
