import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'main.dart';

final _secureStorage = const FlutterSecureStorage();

/// Service class for complaint operations
class ComplaintService {
  // ------------------ AUTH TOKEN ------------------ //
  static Future<String?> _getAuthToken() async {
    try {
      return await _secureStorage.read(key: 'access_token');
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // ------------------ CATEGORY ------------------ //
  static Future<ApiResponse<List<Category>>> getCategories() async {
    try {
      final response = await ApiClient.get('/api/categories');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final categories = data.map((json) => Category.fromJson(json)).toList();
        return ApiResponse.success(categories);
      } else {
        final error = json.decode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to load categories',
        );
      }
    } catch (e) {
      debugPrint('❌ getCategories error: $e');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // ------------------ COMPLAINT SUBMISSION ------------------ //
  static Future<ApiResponse<Complaint>> submitComplaint({
    required String name,
    required String email,
    required String title,
    required String description,
    required String category,
    required String urgency,
    required File imageFile,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    try {
      debugPrint(
        '📤 Submitting complaint to $apiBaseUrl/api/complaints/public',
      );
      debugPrint('  Name: $name, Email: $email, Category: $category');

      final uri = Uri.parse('$apiBaseUrl/api/complaints/public');
      final request = http.MultipartRequest('POST', uri);

      // Add form fields
      request.fields['name'] = name;
      request.fields['email'] = email;
      request.fields['category'] = category;
      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['urgency'] = urgency;
      request.fields['location_latitude'] = latitude.toString();
      request.fields['location_longitude'] = longitude.toString();
      request.fields['location_address'] = address;

      // Add auth token if available
      final token = await _getAuthToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'photo',
          imageFile.path,
          filename: path.basename(imageFile.path),
        ),
      );

      debugPrint(
        '📡 Sending request with ${request.fields.length} fields and ${request.files.length} files',
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint(
        '📥 Response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}',
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        debugPrint('✅ Complaint created successfully with ID: ${data['id']}');
        return ApiResponse.success(Complaint.fromJson(data));
      } else {
        final error = json.decode(response.body);
        final message = _extractErrorMessage(
          error,
          'Failed to submit complaint',
        );
        debugPrint('❌ Server error: $message');
        return ApiResponse.error(message);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ submitComplaint error: $e');
      debugPrint('Stack trace: $stackTrace');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // ------------------ ATTACHMENT UPLOAD ------------------ //
  static Future<ApiResponse<Attachment>> uploadAttachment({
    required String complaintId,
    required File file,
  }) async {
    try {
      final uri = Uri.parse(
        '$apiBaseUrl/api/complaints/$complaintId/attachments',
      );
      final request = http.MultipartRequest('POST', uri);

      final token = await _getAuthToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: path.basename(file.path),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return ApiResponse.success(Attachment.fromJson(data));
      } else {
        final error = json.decode(response.body);
        final message = _extractErrorMessage(error, 'Failed to upload file');
        return ApiResponse.error(message);
      }
    } catch (e) {
      debugPrint('❌ uploadAttachment error: $e');
      return ApiResponse.error('File upload failed: ${e.toString()}');
    }
  }

  // ------------------ USER COMPLAINTS ------------------ //
  static Future<ApiResponse<List<Complaint>>> getUserComplaints() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await ApiClient.get('/api/complaints', headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final complaints = data
            .map((json) => Complaint.fromJson(json))
            .toList();
        return ApiResponse.success(complaints);
      } else {
        final error = json.decode(response.body);
        final message = _extractErrorMessage(
          error,
          'Failed to fetch complaints',
        );
        return ApiResponse.error(message);
      }
    } catch (e) {
      debugPrint('❌ getUserComplaints error: $e');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // ------------------ COMPLAINTS BY EMAIL ------------------ //
  static Future<ApiResponse<List<Complaint>>> getComplaintsByEmail(
    String email,
  ) async {
    try {
      debugPrint('📥 Fetching complaints for email: $email');
      final response = await ApiClient.get('/api/complaints/by-email/$email');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final complaints = data
            .map((json) => Complaint.fromJson(json))
            .toList();
        debugPrint('✅ Fetched ${complaints.length} complaints for $email');
        return ApiResponse.success(complaints);
      } else {
        final error = json.decode(response.body);
        final message = _extractErrorMessage(
          error,
          'Failed to fetch complaints',
        );
        return ApiResponse.error(message);
      }
    } catch (e) {
      debugPrint('❌ getComplaintsByEmail error: $e');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // ------------------ SINGLE COMPLAINT ------------------ //
  // Get public statistics
  static Future<ApiResponse<Map<String, int>>> getPublicStats() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/stats/public'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return ApiResponse.success({
          'total': data['total'] as int,
          'resolved': data['resolved'] as int,
          'pending': data['pending'] as int,
        });
      } else {
        return ApiResponse.error('Failed to fetch statistics');
      }
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // Get user-specific statistics by email
  static Future<ApiResponse<Map<String, int>>> getUserStats(
    String email,
  ) async {
    try {
      debugPrint('📊 Fetching stats for user: $email');
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/stats/user/$email'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        debugPrint(
          '✅ User stats: ${data['total']} total, ${data['resolved']} resolved, ${data['pending']} pending',
        );
        return ApiResponse.success({
          'total': data['total'] as int,
          'resolved': data['resolved'] as int,
          'pending': data['pending'] as int,
        });
      } else {
        return ApiResponse.error('Failed to fetch user statistics');
      }
    } catch (e) {
      debugPrint('❌ getUserStats error: $e');
      return ApiResponse.error(e.toString());
    }
  }

  static Future<ApiResponse<Complaint>> getComplaint(String id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await ApiClient.get(
        '/api/complaints/$id',
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(Complaint.fromJson(data));
      } else {
        final error = json.decode(response.body);
        final message = _extractErrorMessage(error, 'Complaint not found');
        return ApiResponse.error(message);
      }
    } catch (e) {
      debugPrint('❌ getComplaint error: $e');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // ------------------ UTILITIES ------------------ //
  static String _extractErrorMessage(dynamic error, String fallback) {
    if (error is Map && error['detail'] != null) {
      final detail = error['detail'];
      if (detail is String) return detail;
      if (detail is List) return detail.join(', ');
      return detail.toString();
    }
    return fallback;
  }
}

// ===================================================
//  MODELS
// ===================================================

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  ApiResponse._(this.success, this.data, this.error);

  factory ApiResponse.success(T data) => ApiResponse._(true, data, null);
  factory ApiResponse.error(String error) => ApiResponse._(false, null, error);
}

class Category {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final String? color;
  final DateTime? createdAt;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.color,
    this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      icon: json['icon'],
      color: json['color'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }
}

class Complaint {
  final String id;
  final String name;
  final String email;
  final String category;
  final String? title;
  final String description;
  final String? urgency;
  final String? locationAddress;
  final double? latitude;
  final double? longitude;
  final String? photoFilename;
  final String status;
  final DateTime createdAt;

  Complaint({
    required this.id,
    required this.name,
    required this.email,
    required this.category,
    this.title,
    required this.description,
    this.urgency,
    this.locationAddress,
    this.latitude,
    this.longitude,
    this.photoFilename,
    required this.status,
    required this.createdAt,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      category: json['category'] ?? '',
      title: json['title'],
      description: json['description'] ?? '',
      urgency: json['urgency'],
      locationAddress: json['location_address'],
      latitude: (json['location_latitude'] as num?)?.toDouble(),
      longitude: (json['location_longitude'] as num?)?.toDouble(),
      photoFilename: json['photo_filename'],
      status: json['status'] ?? 'Unknown',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class Attachment {
  final String id;
  final String complaintId;
  final String fileName;
  final String filePath;
  final String? fileType;
  final int? fileSize;
  final DateTime createdAt;

  Attachment({
    required this.id,
    required this.complaintId,
    required this.fileName,
    required this.filePath,
    this.fileType,
    this.fileSize,
    required this.createdAt,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['id'] ?? '',
      complaintId: json['complaint_id'] ?? '',
      fileName: json['file_name'] ?? '',
      filePath: json['file_path'] ?? '',
      fileType: json['file_type'],
      fileSize: json['file_size'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
