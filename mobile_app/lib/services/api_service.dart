import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_storage.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api/accounts';
  static const String gamesUrl = 'http://127.0.0.1:8000/api/games';
  static const String walletUrl = 'http://127.0.0.1:8000/api/wallet';

  // ---------------- REGISTER ----------------

  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'phone_number': phoneNumber,
        'password': password,
      }),
    );

    return _handleResponse(response);
  }

  // ---------------- LOGIN ----------------

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    return _handleResponse(response);
  }

  // ---------------- ADMIN LOGIN ----------------

  static Future<Map<String, dynamic>> adminLogin({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin-login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    return _handleResponse(response);
  }

  // ---------------- PASSWORD RESET ----------------

  static Future<Map<String, dynamic>> requestPasswordReset({
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/password-reset/request/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/password-reset/verify/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'otp': otp,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> confirmPasswordReset({
    required String email,
    required String resetToken,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/password-reset/confirm/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'reset_token': resetToken,
        'new_password': newPassword,
      }),
    );

    return _handleResponse(response);
  }

  // ---------------- ADMIN: USERS ----------------

  static Future<Map<String, dynamic>> getAdminUsers({
    String search = '',
    int page = 1,
  }) async {
    final token = await TokenStorage.getAccessToken();

    final uri = Uri.parse('$baseUrl/admin/users/').replace(
      queryParameters: {
        'search': search,
        'page': '$page',
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> setAdminUserStatus({
    required int userId,
    required bool isActive,
  }) async {
    final token = await TokenStorage.getAccessToken();

    final response = await http.patch(
      Uri.parse('$baseUrl/admin/users/$userId/status/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'is_active': isActive}),
    );

    return _handleResponse(response);
  }

  // ---------------- ADMIN: DASHBOARD STATS ----------------

  static Future<Map<String, dynamic>> getAdminStats() async {
    final token = await TokenStorage.getAccessToken();

    final response = await http.get(
      Uri.parse('$baseUrl/admin/stats/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    return _handleResponse(response);
  }

  // ---------------- PUBLIC: GAMES ----------------

  static Future<List<dynamic>> getGames() async {
    final response = await http.get(
      Uri.parse('$gamesUrl/'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);

      if (data is List) return data;

      if (data is Map && data['results'] is List) {
        return data['results'];
      }

      throw Exception('Unexpected games response format.');
    }

    throw Exception('Could not load games: ${response.body}');
  }

  // ---------------- ADMIN: GAMES ----------------

  static Future<List<dynamic>> getAdminGames() async {
    final token = await TokenStorage.getAccessToken();

    final response = await http.get(
      Uri.parse('$gamesUrl/admin/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);

      if (data is List) return data;

      if (data is Map && data['results'] is List) {
        return data['results'];
      }

      throw Exception('Unexpected admin games response format.');
    }

    throw Exception('Could not load admin games: ${response.body}');
  }

  static Future<Map<String, dynamic>> createGame({
    required String name,
    required String slug,
    required String description,
    required String category,
    required String iconName,
    bool isActive = true,
    int sortOrder = 0,
  }) async {
    final token = await TokenStorage.getAccessToken();

    final response = await http.post(
      Uri.parse('$gamesUrl/admin/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'slug': slug,
        'description': description,
        'category': category,
        'icon_name': iconName,
        'is_active': isActive,
        'sort_order': sortOrder,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateGame({
    required int gameId,
    required Map<String, dynamic> changes,
  }) async {
    final token = await TokenStorage.getAccessToken();

    final response = await http.patch(
      Uri.parse('$gamesUrl/admin/$gameId/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(changes),
    );

    return _handleResponse(response);
  }

  static Future<void> deleteGame({
    required int gameId,
  }) async {
    final token = await TokenStorage.getAccessToken();

    final response = await http.delete(
      Uri.parse('$gamesUrl/admin/$gameId/'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 204 &&
        (response.statusCode < 200 || response.statusCode >= 300)) {
      throw Exception('Could not delete game: ${response.body}');
    }
  }

  // ---------------- WALLET APIS ----------------

  static Future<Map<String, dynamic>> getWallet() async {
    final token = await TokenStorage.getAccessToken();

    final response = await http.get(
      Uri.parse('$walletUrl/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> deposit({
    required double amount,
    String paymentMethod = 'UPI / Demo',
  }) async {
    final token = await TokenStorage.getAccessToken();

    final response = await http.post(
      Uri.parse('$walletUrl/deposit/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'amount': amount.toStringAsFixed(2),
        'payment_method': paymentMethod,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> requestWhatsAppDeposit({
    required double amount,
  }) async {
    final token = await TokenStorage.getAccessToken();

    final response = await http.post(
      Uri.parse('$walletUrl/deposit/whatsapp/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'amount': amount.toStringAsFixed(2),
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> withdraw({
    required double amount,
    String accountInfo = 'UPI',
  }) async {
    final token = await TokenStorage.getAccessToken();

    final response = await http.post(
      Uri.parse('$walletUrl/withdraw/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'amount': amount.toStringAsFixed(2),
        'account_info': accountInfo,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getTransactions({int page = 1}) async {
    final token = await TokenStorage.getAccessToken();

    final response = await http.get(
      Uri.parse('$walletUrl/transactions/?page=$page'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    return _handleResponse(response);
  }

  // ---------------- ADMIN: DEPOSITS & TRANSACTIONS ----------------

  static Future<Map<String, dynamic>> getAdminDeposits({
    String status = '',
    String search = '',
    int page = 1,
  }) async {
    final token = await TokenStorage.getAccessToken();

    final uri = Uri.parse('$walletUrl/admin/deposits/').replace(
      queryParameters: {
        if (status.isNotEmpty) 'status': status,
        if (search.isNotEmpty) 'search': search,
        'page': '$page',
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> approveAdminDeposit({
    required int transactionId,
  }) async {
    final token = await TokenStorage.getAccessToken();

    final response = await http.post(
      Uri.parse('$walletUrl/admin/deposits/$transactionId/approve/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> rejectAdminDeposit({
    required int transactionId,
    String reason = 'Payment verification unconfirmed',
  }) async {
    final token = await TokenStorage.getAccessToken();

    final response = await http.post(
      Uri.parse('$walletUrl/admin/deposits/$transactionId/reject/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'reason': reason}),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> adminAdjustWallet({
    required int userId,
    required String action,
    required double amount,
    String description = '',
  }) async {
    final token = await TokenStorage.getAccessToken();

    final response = await http.post(
      Uri.parse('$walletUrl/admin/$userId/adjust/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'action': action,
        'amount': amount.toStringAsFixed(2),
        'description': description,
      }),
    );

    return _handleResponse(response);
  }

  // ---------------- MINES GAME APIS ----------------

  static Future<Map<String, dynamic>> getMinesActiveSession() async {
    final token = await TokenStorage.getAccessToken();

    final response = await http.get(
      Uri.parse('$gamesUrl/mines/active/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> startMinesGame({
    required double betAmount,
    required int mineCount,
  }) async {
    final token = await TokenStorage.getAccessToken();

    final response = await http.post(
      Uri.parse('$gamesUrl/mines/start/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'bet_amount': betAmount.toStringAsFixed(2),
        'mine_count': mineCount,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> revealMinesTile({
    required int sessionId,
    required int tileIndex,
  }) async {
    final token = await TokenStorage.getAccessToken();

    final response = await http.post(
      Uri.parse('$gamesUrl/mines/reveal/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'session_id': sessionId,
        'tile_index': tileIndex,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> cashoutMines({
    required int sessionId,
  }) async {
    final token = await TokenStorage.getAccessToken();

    final response = await http.post(
      Uri.parse('$gamesUrl/mines/cashout/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'session_id': sessionId,
      }),
    );

    return _handleResponse(response);
  }

  // ---------------- RESPONSE HANDLER ----------------

  static Map<String, dynamic> _handleResponse(
    http.Response response,
  ) {
    dynamic data;

    try {
      data = jsonDecode(response.body);
    } catch (_) {
      data = {'message': response.body};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (data is Map<String, dynamic>) {
        return data;
      }

      return {'data': data};
    }

    if (data is Map<String, dynamic>) {
      if (data.containsKey('error')) {
        throw Exception(data['error']);
      }
      if (data.containsKey('detail')) {
        throw Exception(data['detail']);
      }
    }

    throw Exception(data.toString());
  }
}
