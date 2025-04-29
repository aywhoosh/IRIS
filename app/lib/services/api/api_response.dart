class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
  });

  // Create a successful response
  factory ApiResponse.success(T? data, {String message = 'Success'}) {
    return ApiResponse(
      success: true,
      message: message,
      data: data,
    );
  }

  // Create an error response
  factory ApiResponse.error(String message) {
    return ApiResponse(
      success: false,
      message: message,
    );
  }
}
