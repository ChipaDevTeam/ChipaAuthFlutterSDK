class ChipaAuthError implements Exception {
  final String message;
  final int? statusCode;
  final Object? cause;

  const ChipaAuthError(this.message, {this.statusCode, this.cause});

  @override
  String toString() => 'ChipaAuthError($statusCode): $message';
}
