import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../models/user.dart';

class SupabaseService {
  final _supabase = supabase.Supabase.instance.client;
  // Get the currently logged in user
  User? get currentUser {
    final userData = _supabase.auth.currentUser;
    if (userData == null) return null;
    return User(
      id: userData.id,
      email: userData.email ?? '',
      firstName: userData.userMetadata?['first_name'] ?? '',
      lastName: userData.userMetadata?['last_name'] ?? '',
      createdAt: DateTime.parse(userData.createdAt),
    );
  }

  // Check if the user is authenticated
  bool get isAuthenticated => _supabase.auth.currentUser != null;

  // Authentication methods
  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  // Profile management
  Future<void> updateProfile({
    required String firstName,
    required String lastName,
  }) async {
    try {
      await _supabase.from('profiles').update({
        'first_name': firstName,
        'last_name': lastName,
      }).eq('id', _supabase.auth.currentUser!.id);
    } catch (e) {
      rethrow;
    }
  }

  // Scan methods
  Future<String> uploadScanImage(File imageFile, String eyeSide) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final userId = _supabase.auth.currentUser!.id;
      final filePath = 'scans/$userId/$timestamp.jpg';

      // Upload image to storage
      await _supabase.storage.from('images').upload(
            filePath,
            imageFile,
            fileOptions:
                supabase.FileOptions(cacheControl: '3600', upsert: false),
          );

      // Get public URL
      final imageUrl = _supabase.storage.from('images').getPublicUrl(filePath);

      // Create a new scan record
      final response = await _supabase
          .from('scans')
          .insert({
            'user_id': userId,
            'image_path': imageUrl,
            'eye_side': eyeSide,
          })
          .select()
          .single();

      return response['id'] as String;
    } catch (e) {
      if (e.toString().contains('violates row-level security policy')) {
        throw Exception(
            'Permission denied: You do not have permission to upload scans. Please check RLS policies.');
      } else if (e.toString().contains('storage')) {
        throw Exception(
            'Storage error: Unable to upload image. Please check storage bucket permissions.');
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getUserScans() async {
    try {
      final response = await _supabase
          .from('scans')
          .select('*, scan_results!scan_results_scan_id_fkey(*)')
          .order('created_at', ascending: false);

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getScanDetails(String scanId) async {
    try {
      final response = await _supabase
          .from('scans')
          .select(
              '*, scan_results!scan_results_scan_id_fkey(*)') // Specify the relationship
          .eq('id', scanId)
          .single();

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> processScan(String scanId) async {
    try {
      // In a real application, this would trigger a processing function
      // on a serverless function or backend service

      // Simulate a more realistic processing flow with status updates
      await _supabase
          .from('scans')
          .update({'status': 'processing'}).eq('id', scanId);

      await Future.delayed(const Duration(seconds: 1));
      await Future.delayed(const Duration(seconds: 1));
      await Future.delayed(const Duration(seconds: 1));
      await Future.delayed(const Duration(seconds: 1));

      // Final update - set status to completed
      await _supabase
          .from('scans')
          .update({'status': 'completed'}).eq('id', scanId);

      // Get details about the scan
      final scanDetails = await _supabase
          .from('scans')
          .select('eye_side')
          .eq('id', scanId)
          .single();

      // Generate a random condition for demo purposes
      final conditions = [
        'healthy',
        'cataract',
        'glaucoma',
        'pterygium',
        'keratoconus',
        'strabismus',
        'pink_eye',
        'stye',
        'trachoma',
        'uveitis'
      ];

      // Randomly select a condition (for demonstration)
      final random = Random();
      final selectedCondition = conditions[random.nextInt(conditions.length)];

      // Severity levels based on condition
      final Map<String, List<String>> severityByCondition = {
        'healthy': ['NONE'],
        'cataract': ['MILD', 'MODERATE', 'SEVERE'],
        'glaucoma': ['EARLY', 'MODERATE', 'ADVANCED'],
        'pterygium': ['MILD', 'MODERATE', 'SEVERE'],
        'keratoconus': ['EARLY', 'MODERATE', 'ADVANCED'],
        'strabismus': ['MILD', 'MODERATE', 'SEVERE'],
        'pink_eye': ['MILD', 'MODERATE', 'SEVERE'],
        'stye': ['SMALL', 'MEDIUM', 'LARGE'],
        'trachoma': ['EARLY', 'MODERATE', 'ADVANCED'],
        'uveitis': ['MILD', 'MODERATE', 'SEVERE'],
      };

      // Select appropriate severity for the condition
      final severities = severityByCondition[selectedCondition] ?? ['UNKNOWN'];
      final selectedSeverity = severities[random.nextInt(severities.length)];

      // Generate appropriate confidence based on condition and severity
      double confidence = 0;
      if (selectedCondition == 'healthy') {
        confidence = 0.90 + random.nextDouble() * 0.09; // 0.90-0.99
      } else {
        // Lower confidence for abnormal conditions
        confidence = 0.75 + random.nextDouble() * 0.20; // 0.75-0.95
      }

      // Generate appropriate diagnosis text
      final Map<String, String> diagnosisByCondition = {
        'healthy': 'No abnormalities detected. Your eye appears healthy.',
        'cataract':
            'Clouding of the normally clear lens of the eye, affecting vision quality.',
        'glaucoma':
            'Optic nerve damage, typically caused by abnormally high pressure in your eye.',
        'pterygium':
            'Growth of pink, fleshy tissue on the conjunctiva, often extending to the cornea.',
        'keratoconus':
            'Thinning and bulging of the cornea, causing distorted vision.',
        'strabismus':
            'Misalignment of the eyes, where both eyes don\'t look at the same place at the same time.',
        'pink_eye':
            'Inflammation or infection of the transparent membrane that lines your eyelid and covers the white part of your eyeball.',
        'stye':
            'Painful red bump along the edge of your eyelid, caused by an infected oil gland.',
        'trachoma':
            'Bacterial infection affecting the conjunctiva and cornea, potentially leading to blindness if untreated.',
        'uveitis':
            'Inflammation of the middle layer of the eye, which can lead to reduced vision or blindness.',
      };

      final diagnosis = diagnosisByCondition[selectedCondition] ??
          'Unspecified condition detected.';

      // Insert randomized result
      await _supabase.from('scan_results').insert({
        'scan_id': scanId,
        'condition': selectedCondition,
        'severity': selectedSeverity,
        'confidence': confidence,
        'diagnosis': diagnosis,
        'recommendations': {
          'suggestions': _getRecommendationsForCondition(selectedCondition)
        }
      });
    } catch (e) {
      if (e.toString().contains('violates row-level security policy')) {
        throw Exception(
            'Permission denied: RLS policy violated. Please check your database policies for scan_results table.');
      }
      rethrow;
    }
  }

  // Helper method to get condition-specific recommendations
  List<String> _getRecommendationsForCondition(String condition) {
    switch (condition) {
      case 'healthy':
        return [
          'Continue regular eye check-ups',
          'Maintain a healthy diet rich in vitamins A and E',
          'Use eye protection in bright sunlight',
          'Take regular breaks when using digital screens (20-20-20 rule)'
        ];
      case 'cataract':
        return [
          'Consult an ophthalmologist for proper evaluation',
          'Consider cataract surgery if vision is significantly affected',
          'Use brighter lighting for reading and other activities',
          'Protect your eyes from UV exposure with sunglasses'
        ];
      case 'glaucoma':
        return [
          'Take prescribed eye drops regularly to control intraocular pressure',
          'Have regular eye pressure checks',
          'Avoid activities that increase eye pressure',
          'Consider lifestyle changes like moderate exercise and balanced diet'
        ];
      case 'pterygium':
        return [
          'Protect eyes from sunlight, wind, and dust with sunglasses',
          'Use artificial tears to keep the eye surface moist',
          'Avoid dry, dusty environments when possible',
          'Consider surgical removal if vision is affected or for cosmetic reasons'
        ];
      case 'keratoconus':
        return [
          'Consider specialized contact lenses for vision correction',
          'Avoid rubbing eyes as it can worsen the condition',
          'Regular follow-ups with your eye doctor to monitor progression',
          'Discuss corneal cross-linking procedure to prevent progression'
        ];
      case 'strabismus':
        return [
          'Consider vision therapy exercises',
          'Consult an ophthalmologist about potential corrective surgery',
          'Use prescribed eyeglasses or prism lenses if recommended',
          'For children, patching treatment may be recommended'
        ];
      case 'pink_eye':
        return [
          'Avoid touching or rubbing your eyes',
          'Wash hands frequently to prevent spreading infection',
          'Use cool compresses to relieve discomfort',
          'Complete the full course of prescribed antibiotics if bacterial'
        ];
      case 'stye':
        return [
          'Apply warm compresses to the affected eye several times daily',
          'Keep the eyelid clean and avoid eye makeup',
          'Do not squeeze or try to pop the stye',
          'Consult a doctor if it doesn\'t improve within a week'
        ];
      case 'trachoma':
        return [
          'Complete the full course of prescribed antibiotics',
          'Practice good hygiene - wash face and hands regularly',
          'Avoid sharing towels, pillows, or other personal items',
          'Consider surgery for eyelid correction in advanced cases'
        ];
      case 'uveitis':
        return [
          'Take anti-inflammatory medications as prescribed',
          'Protect eyes from bright light with sunglasses',
          'Regular follow-up visits to monitor the condition',
          'Discuss long-term management strategies with your ophthalmologist'
        ];
      default:
        return [
          'Consult with an ophthalmologist for proper evaluation',
          'Protect your eyes from UV exposure with sunglasses',
          'Maintain good eye hygiene and overall health',
          'Schedule regular eye examinations'
        ];
    }
  }

  // Real-time subscriptions
  StreamSubscription subscribeToPendingScans(
      Function(List<Map<String, dynamic>>) onScanChanged) {
    final userId = _supabase.auth.currentUser!.id;

    return _supabase
        .from('scans')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen((data) {
          onScanChanged(data);
        });
  }

  Future<bool> deleteScan(String scanId) async {
    try {
      //Get image path before deleting the scan record
      final scan = await _supabase
          .from('scans')
          .select('image_path')
          .eq('id', scanId)
          .single();

      String? imagePath = scan['image_path']?.toString();

      // Delete the scan (scan_results will be deleted automatically due to CASCADE)
      final result =
          await _supabase.from('scans').delete().eq('id', scanId).select();

      // Delete image if needed
      if (imagePath != null && imagePath.contains('images/scans/')) {
        final storagePath = imagePath.split('images/').last;
        await _supabase.storage.from('images').remove([storagePath]);
      }

      return result.isNotEmpty;
    } catch (e) {
      print('Error deleting scan: $e');
      return false;
    }
  }
}
