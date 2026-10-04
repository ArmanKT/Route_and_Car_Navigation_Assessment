import 'package:dio/dio.dart';
import 'package:route_and_car_navigation/app/core/exceptions/route_failure.dart';
import 'package:route_and_car_navigation/app/core/network/interceptor/api_interceptor.dart';
import 'package:route_and_car_navigation/app/core/shared/data/model/api_response_model.dart';
import 'package:route_and_car_navigation/environment.dart';

class ApiClient {
  final Dio _dio;

  ApiClient({Dio? dio, String? baseUrl})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? Environment.current.routingBaseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                sendTimeout: const Duration(seconds: 15),
                headers: {
                  'Content-Type': 'application/json',
                },
              ),
            ) {
    if (dio == null) {
      _dio.interceptors.add(ApiInterceptor());
    }
  }

  Dio get dio => _dio;

  /// Performs HTTP GET request and maps to typed ApiResponse
  Future<ApiResponse<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      );

      return ApiResponse.success(
        response.data,
        statusCode: response.statusCode ?? 200,
        message: response.statusMessage ?? 'Success',
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw const RouteTimeoutException('Request was cancelled');
      }

      if (e.response?.statusCode == 429) {
        throw const ServerRateLimitException();
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw const RouteTimeoutException();
      }

      throw NetworkFailureException(
        e.message ?? 'Network failure occurred while connecting to server',
      );
    } catch (e) {
      throw NetworkFailureException('Unexpected error: $e');
    }
  }
}
