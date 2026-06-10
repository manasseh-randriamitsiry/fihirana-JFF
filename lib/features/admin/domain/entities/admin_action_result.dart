/// Admin action result entity
class AdminActionResult {
  final bool success;
  final String message;
  final String? errorCode;
  final Map<String, dynamic>? data;

  const AdminActionResult({
    required this.success,
    required this.message,
    this.errorCode,
    this.data,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdminActionResult &&
        other.success == success &&
        other.message == message &&
        other.errorCode == errorCode &&
        other.data == data;
  }

  @override
  int get hashCode {
    return success.hashCode ^
        message.hashCode ^
        errorCode.hashCode ^
        data.hashCode;
  }

  factory AdminActionResult.success(String message,
      {Map<String, dynamic>? data}) {
    return AdminActionResult(
      success: true,
      message: message,
      data: data,
    );
  }

  factory AdminActionResult.error(String message, {String? errorCode}) {
    return AdminActionResult(
      success: false,
      message: message,
      errorCode: errorCode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'message': message,
      'errorCode': errorCode,
      'data': data,
    };
  }

  factory AdminActionResult.fromMap(Map<String, dynamic> map) {
    return AdminActionResult(
      success: map['success'] ?? false,
      message: map['message'] ?? '',
      errorCode: map['errorCode'],
      data: map['data'],
    );
  }
}
