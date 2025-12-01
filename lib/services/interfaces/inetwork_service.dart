/// Abstract interface for Network service operations
/// This allows for dependency injection and better testability
abstract class INetworkService {
  /// Initialize the network service
  Future<void> initialize();
  
  /// Check if device has internet connection
  Future<bool> isConnected();
  
  /// Check if device is on WiFi
  Future<bool> isOnWifi();
  
  /// Check if device is on mobile data
  Future<bool> isOnMobileData();
  
  /// Monitor network connectivity changes
  Stream<bool> get connectivityStream;
  
  /// Get current network type
  Future<NetworkType> getNetworkType();
  
  /// Make HTTP GET request
  Future<NetworkResponse> get(String url, {Map<String, String>? headers});
  
  /// Make HTTP POST request
  Future<NetworkResponse> post(String url, {dynamic body, Map<String, String>? headers});
  
  /// Make HTTP PUT request
  Future<NetworkResponse> put(String url, {dynamic body, Map<String, String>? headers});
  
  /// Make HTTP DELETE request
  Future<NetworkResponse> delete(String url, {Map<String, String>? headers});
  
  /// Download file
  Future<void> downloadFile(String url, String savePath, {ProgressCallback? onProgress});
  
  /// Upload file
  Future<NetworkResponse> uploadFile(String url, String filePath, {ProgressCallback? onProgress});
  
  /// Set timeout for requests
  void setTimeout(Duration timeout);
  
  /// Set retry policy
  void setRetryPolicy(int maxRetries, Duration retryDelay);
  
  /// Add request interceptor
  void addRequestInterceptor(RequestInterceptor interceptor);
  
  /// Add response interceptor
  void addResponseInterceptor(ResponseInterceptor interceptor);
  
  /// Clear all caches
  Future<void> clearCache();
  
  /// Get network statistics
  Future<NetworkStats> getStats();
}

/// Network types
enum NetworkType {
  none,
  wifi,
  mobile,
  ethernet,
  other,
}

/// Network response wrapper
class NetworkResponse {
  final bool success;
  final int? statusCode;
  final dynamic data;
  final String? error;
  final Map<String, String>? headers;
  
  NetworkResponse({
    required this.success,
    this.statusCode,
    this.data,
    this.error,
    this.headers,
  });
  
  factory NetworkResponse.success(dynamic data, {int? statusCode, Map<String, String>? headers}) {
    return NetworkResponse(
      success: true,
      statusCode: statusCode,
      data: data,
      headers: headers,
    );
  }
  
  factory NetworkResponse.error(String error, {int? statusCode}) {
    return NetworkResponse(
      success: false,
      statusCode: statusCode,
      error: error,
    );
  }
}

/// Progress callback for file operations
typedef ProgressCallback = void Function(double progress);

/// Request interceptor
typedef RequestInterceptor = Future<Map<String, String>> Function(Map<String, String> headers);

/// Response interceptor
typedef ResponseInterceptor = Future<NetworkResponse> Function(NetworkResponse response);

/// Network statistics
class NetworkStats {
  final int totalRequests;
  final int successfulRequests;
  final int failedRequests;
  final int totalBytesDownloaded;
  final int totalBytesUploaded;
  final Duration averageResponseTime;
  
  NetworkStats({
    required this.totalRequests,
    required this.successfulRequests,
    required this.failedRequests,
    required this.totalBytesDownloaded,
    required this.totalBytesUploaded,
    required this.averageResponseTime,
  });
  
  double get successRate => totalRequests > 0 ? (successfulRequests / totalRequests) * 100 : 0;
}