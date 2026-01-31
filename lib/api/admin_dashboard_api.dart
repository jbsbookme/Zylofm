import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

@immutable
class DashboardDj {
  final String id;
  final String name;
  final String? instagram;
  final String? bio;

  const DashboardDj({
    required this.id,
    required this.name,
    this.instagram,
    this.bio,
  });

  factory DashboardDj.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as String? ?? '').trim();
    final name = (json['name'] as String? ?? '').trim();
    final instagram = (json['instagram'] as String?)?.trim();
    final bio = (json['bio'] as String?)?.trim();

    return DashboardDj(
      id: id,
      name: name,
      instagram: (instagram != null && instagram.isNotEmpty) ? instagram : null,
      bio: (bio != null && bio.isNotEmpty) ? bio : null,
    );
  }
}

class AdminDashboardApi {
  final String baseUrl;
  final http.Client _client;

  AdminDashboardApi({required this.baseUrl, http.Client? client}) : _client = client ?? http.Client();

  Uri _u(String path) {
    final raw = baseUrl.trim().endsWith('/') ? baseUrl.trim().substring(0, baseUrl.trim().length - 1) : baseUrl.trim();
    return Uri.parse('$raw$path');
  }

  Future<List<DashboardDj>> listApprovedDjs() async {
    final resp = await _client.get(_u('/api/public/djs'));
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('GET /api/public/djs failed (${resp.statusCode})');
    }

    final decoded = jsonDecode(resp.body);
    if (decoded is Map<String, dynamic>) {
      final items = decoded['items'];
      if (items is List) {
        return items.whereType<Map>().map((e) => DashboardDj.fromJson(e.cast<String, dynamic>())).toList();
      }
    }
    return const [];
  }

  Future<String?> getRadioStreamUrl() async {
    final resp = await _client.get(_u('/api/public/radio'));
    if (resp.statusCode == 404) return null;
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('GET /api/public/radio failed (${resp.statusCode})');
    }

    final decoded = jsonDecode(resp.body);
    if (decoded is Map<String, dynamic>) {
      final url = (decoded['streamUrl'] as String?)?.trim();
      return (url != null && url.isNotEmpty) ? url : null;
    }

    return null;
  }

  Future<String> registerDj({
    required String name,
    String? email,
    String? phone,
    String? instagram,
    String? bio,
  }) async {
    final resp = await _client.post(
      _u('/api/public/djs/register'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name.trim(),
        'email': (email ?? '').trim(),
        'phone': (phone ?? '').trim(),
        'instagram': (instagram ?? '').trim(),
        'bio': (bio ?? '').trim(),
      }),
    );

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      String msg = 'POST /api/public/djs/register failed (${resp.statusCode})';
      try {
        final decoded = jsonDecode(resp.body);
        if (decoded is Map<String, dynamic>) {
          final err = (decoded['error'] as String?)?.trim();
          if (err != null && err.isNotEmpty) msg = err;
        }
      } catch (_) {}
      throw Exception(msg);
    }

    final decoded = jsonDecode(resp.body);
    if (decoded is Map<String, dynamic>) {
      final id = (decoded['id'] as String?)?.trim();
      if (id != null && id.isNotEmpty) return id;
    }

    throw Exception('Invalid response from DJ register');
  }

  void close() => _client.close();
}
