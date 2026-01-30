import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_config.dart';

class AuthService with ChangeNotifier {
  String get _baseUrl => AppConfig.baseUrl;

  // Use SharedPreferences for Web compatibility, SecureStorage for Mobile
  final _storage = const FlutterSecureStorage();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  User? _currentUser;
  User? get currentUser => _currentUser;

  bool get isAdmin => _currentUser?.role == 'admin';
  bool get isInitialized => !_isLoading;

  // Migration Helpers
  String? get uid => _currentUser?.id;

  Future<void> tryAutoLogin() async {
    try {
      String? token;
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString('auth_token');
        final userData = prefs.getString('user_data');
        if (userData != null) {
          _currentUser = User.fromJson(jsonDecode(userData));
        }
      } else {
        token = await _storage.read(key: 'auth_token');
        String? userData = await _storage.read(key: 'user_data');
        if (userData != null) {
          _currentUser = User.fromJson(jsonDecode(userData));
        }
      }

      if (token != null && _currentUser != null) {
        // success
      }
    } catch (e) {
      debugPrint('Auto login failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String identifier, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'identifier': identifier, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final user = User.fromJson(data['user']);

        _currentUser = user;

        if (kIsWeb) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
          await prefs.setString('user_data', jsonEncode(user.toJson()));
        } else {
          await _storage.write(key: 'auth_token', value: token);
          await _storage.write(
            key: 'user_data',
            value: jsonEncode(user.toJson()),
          );
        }
      } else {
        throw Exception(jsonDecode(response.body)['error'] ?? 'Login failed');
      }
    } catch (e) {
      debugPrint('Login error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    String? name,
    String? profileImageUrl,
    String? phone,
    String? email,
  }) async {
    if (_currentUser == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/users/${_currentUser!.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'profile_image_url': profileImageUrl,
          'phone': phone,
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // data is just the user object
        _currentUser = User.fromJson(data);

        // Update storage
        if (kIsWeb) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'user_data',
            jsonEncode(_currentUser!.toJson()),
          );
        } else {
          await _storage.write(
            key: 'user_data',
            value: jsonEncode(_currentUser!.toJson()),
          );
        }
      } else {
        throw Exception('Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Update profile error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _currentUser = null;
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_data');
    } else {
      await _storage.delete(key: 'auth_token');
      await _storage.delete(key: 'user_data');
    }
    notifyListeners();
  }

  // Method stubs to prevent compilation errors in existing code
  // Method stubs to prevent compilation errors in existing code
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return; // User canceled the sign-in
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken != null) {
        // Send to backend for verification and login/signup
        final response = await http.post(
          Uri.parse('$_baseUrl/auth/google'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'idToken': idToken,
            'name': googleUser.displayName,
            'email': googleUser.email,
            'photoUrl': googleUser.photoUrl,
            'force_create': true,
          }),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          final token = data['token'];
          final user = User.fromJson(data['user']);

          _currentUser = user;

          if (kIsWeb) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('auth_token', token);
            await prefs.setString('user_data', jsonEncode(user.toJson()));
          } else {
            await _storage.write(key: 'auth_token', value: token);
            await _storage.write(
              key: 'user_data',
              value: jsonEncode(user.toJson()),
            );
          }
        } else {
          throw Exception(
            jsonDecode(response.body)['error'] ?? 'Google Sign In failed',
          );
        }
      }
    } catch (e) {
      debugPrint('Google Sign In error: $e');
      // If user cancelled, it might throw an exception, so we just log it.
      // rethrow; // Optional: decide if UI needs to show error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUpWithEmail({
    required String name,
    required String password,
    String? phone,
    String? email,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'password': password,
          'phone': phone,
          'email': email,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Signup response data: $data');
        final token = data['token'];
        final user = User.fromJson(data['user']);

        _currentUser = user;

        if (kIsWeb) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
          await prefs.setString('user_data', jsonEncode(user.toJson()));
        } else {
          await _storage.write(key: 'auth_token', value: token);
          await _storage.write(
            key: 'user_data',
            value: jsonEncode(user.toJson()),
          );
        }
        debugPrint('Signup completed and user stored locally');
      } else {
        String errorMsg = 'Sign up failed';
        try {
          final errorData = jsonDecode(response.body);
          errorMsg = errorData['error'] ?? errorMsg;
        } catch (_) {
          errorMsg =
              'Server Error: ${response.statusCode} - ${response.reasonPhrase}';
        }
        debugPrint('Signup failed with message: $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('Sign up error caught in AuthService: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    await login(email, password);
  }

  Future<void> makeMeAdmin() async {
    if (_currentUser == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/admin/promote'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': _currentUser!.id}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentUser = User.fromJson(data['user']);

        // Update storage
        if (kIsWeb) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'user_data',
            jsonEncode(_currentUser!.toJson()),
          );
        } else {
          await _storage.write(
            key: 'user_data',
            value: jsonEncode(_currentUser!.toJson()),
          );
        }
      } else {
        throw Exception('Promotion failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Admin promote error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkAdmin() async {
    // Stub
  }
}
