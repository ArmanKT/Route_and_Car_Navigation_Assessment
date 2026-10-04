class ApiResponse<T> {
  final int statusCode;
  final String message;
  final T? data;
  final bool isSuccess;

  const ApiResponse({
    required this.statusCode,
    required this.message,
    this.data,
    required this.isSuccess,
  });

  factory ApiResponse.success(T data, {int statusCode = 200, String message = 'Success'}) {
    return ApiResponse(
      statusCode: statusCode,
      message: message,
      data: data,
      isSuccess: true,
    );
  }

  factory ApiResponse.failure(String message, {int statusCode = 400}) {
    return ApiResponse(
      statusCode: statusCode,
      message: message,
      data: null,
      isSuccess: false,
    );
  }
}
