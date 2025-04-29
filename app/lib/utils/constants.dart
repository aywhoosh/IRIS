class AppConstants {
  // API endpoints
  static const String baseUrl =
      'https://weaqcqqbagnycxywvldd.supabase.co'; // Replace with your actual API URL
  static const String apiVersion = '/api/v1';

  //Supabase configuration
  static const String supabaseUrl = 'https://weaqcqqbagnycxywvldd.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndlYXFjcXFiYWdueWN4eXd2bGRkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU5NTE3MzYsImV4cCI6MjA2MTUyNzczNn0.RNZVohEAx5I3UscnfkltjyGxwYXFzS8RKpcKSq3HZjA';

  // Auth endpoints
  static const String loginEndpoint = '$apiVersion/auth/login';
  static const String registerEndpoint = '$apiVersion/auth/register';
  static const String refreshTokenEndpoint = '$apiVersion/auth/refresh';
  static const String userProfileEndpoint = '$apiVersion/auth/me';

  // Scan endpoints
  static const String uploadScanEndpoint = '$apiVersion/scans';
  static const String userScansEndpoint = '$apiVersion/scans/user/me';
  static const String scanDetailsEndpoint = '$apiVersion/scans/'; // + scanId
  static const String jobStatusEndpoint = '$apiVersion/jobs/'; // + jobId

  // Local storage keys
  static const String authTokenKey = 'auth_token';
  static const String userDataKey = 'user_data';

  // App settings
  static const String appName = 'IRIS';
  static const String appVersion = '1.0.0';
}
