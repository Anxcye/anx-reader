/// Generates a unique request ID for request correlation.
///
/// Uses timestamp-based generation to provide sufficient uniqueness
/// for request tracing and debugging in a single-threaded Dart environment.
/// Collision risk is minimal (millisecond precision).
///
/// This approach avoids requiring additional dependencies (like UUID libraries)
/// while still providing meaningful, sortable, and unique identifiers.
///
/// Returns a request ID in the format: `req_<timestamp>`
/// Example: `req_1697123456789`
String generateRequestId() {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  return 'req_$timestamp';
}
