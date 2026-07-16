import 'dart:async';

/// Debouncer utility for search input.
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  /// Run the action after the debounce period.
  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  /// Cancel any pending action.
  void cancel() {
    _timer?.cancel();
  }

  /// Dispose the debouncer.
  void dispose() {
    _timer?.cancel();
  }
}
