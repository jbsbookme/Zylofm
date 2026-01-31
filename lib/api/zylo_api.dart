import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

@immutable
class ApiDj {
  final String id;
  final String displayName;
  final String bio;
  final String? location;
  final List<String> genres;
  final String status;

  const ApiDj({
    required this.id,
    required this.displayName,
    required this.bio,
    required this.status,
    this.location,
    this.genres = const [],
  });

  factory ApiDj.fromJson(Map<String, dynamic> json) {
    return ApiDj(
      id: (json['id'] as String? ?? '').trim(),
      displayName: (json['displayName'] as String? ?? '').trim(),
      bio: (json['bio'] as String? ?? '').trim(),
      location: (json['location'] as String?)?.trim(),
      genres: (json['genres'] as List?)?.whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty).toList() ?? const [],
      status: (json['status'] as String? ?? '').trim(),
    );
  }
}

@immutable
class ApiMix {
  final String id;
  final String djId;
  final String? djName;
  final String title;
  final String description;
  final String genre;
  final String audioUrl;
  final String coverUrl;
  final String status; // pending/approved/rejected
  final bool isClean;
  final DateTime createdAt;

  const ApiMix({
    required this.id,
    required this.djId,
    required this.title,
    required this.description,
    required this.genre,
    required this.audioUrl,
    required this.coverUrl,
    required this.status,
    required this.isClean,
    required this.createdAt,
    this.djName,
  });

  factory ApiMix.fromJson(Map<String, dynamic> json) {
    final createdRaw = json['createdAt'];
    DateTime created;
    if (createdRaw is String) {
      created = DateTime.tryParse(createdRaw) ?? DateTime.now();
    } else {
      created = DateTime.now();
    }

    return ApiMix(
      id: (json['id'] as String? ?? '').trim(),
      djId: (json['djId'] as String? ?? '').trim(),
      djName: (json['djName'] as String?)?.trim(),
      title: (json['title'] as String? ?? '').trim(),
      description: (json['description'] as String? ?? '').trim(),
      genre: (json['genre'] as String? ?? '').trim(),
      audioUrl: (json['audioUrl'] as String? ?? '').trim(),
      coverUrl: (json['coverUrl'] as String? ?? '').trim(),
      status: (json['status'] as String? ?? '').trim(),
      isClean: json['isClean'] == true,
      createdAt: created,
    );
  }
}

@immutable
class ApiAssistantLibraryItem {
  final String id;
  final String title;
  final String audioUrl;
  final List<String> keywords;
  final bool isActive;
  final DateTime updatedAt;

  const ApiAssistantLibraryItem({
    required this.id,
    required this.title,
    required this.audioUrl,
    required this.keywords,
    required this.isActive,
    required this.updatedAt,
  });

  factory ApiAssistantLibraryItem.fromJson(Map<String, dynamic> json) {
    final updatedRaw = json['updatedAt'];
    DateTime updated;
    if (updatedRaw is String) {
      updated = DateTime.tryParse(updatedRaw) ?? DateTime.now();
    } else {
      updated = DateTime.now();
    }

    return ApiAssistantLibraryItem(
      id: (json['id'] as String? ?? '').trim(),
      title: (json['title'] as String? ?? '').trim(),
      audioUrl: (json['audioUrl'] as String? ?? '').trim(),
      keywords: (json['keywords'] as List?)?.whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty).toList() ?? const [],
      isActive: json['isActive'] == true,
      updatedAt: updated,
    );
  }
}

class ZyloApi {
  final String baseUrl;
  final http.Client _client;

  ZyloApi({required this.baseUrl, http.Client? client}) : _client = client ?? http.Client();

  Uri _u(String path) {
    final raw = baseUrl.trim().endsWith('/') ? baseUrl.trim().substring(0, baseUrl.trim().length - 1) : baseUrl.trim();
    return Uri.parse('$raw$path');
  }

  Future<String> login({required String email, required String password}) async {
    final resp = await _client.post(
      _u('/auth/login'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim(), 'password': password}),
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Login failed (${resp.statusCode})');
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final token = (json['access_token'] as String?)?.trim();
    if (token == null || token.isEmpty) throw Exception('No token returned');
    return token;
  }

  Future<ApiDj> getDjMe({required String token}) async {
    final resp = await _client.get(
      _u('/dj/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('GET /dj/me failed (${resp.statusCode})');
    }
    return ApiDj.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  Future<List<ApiDj>> listDjs() async {
    final resp = await _client.get(_u('/djs'));
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('GET /djs failed (${resp.statusCode})');
    }
    final list = jsonDecode(resp.body);
    if (list is! List) return const [];
    return list.whereType<Map>().map((e) => ApiDj.fromJson(e.cast<String, dynamic>())).toList();
  }

  Future<List<ApiMix>> listPublicMixes() async {
    final resp = await _client.get(_u('/mixes/public'));
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('GET /mixes/public failed (${resp.statusCode})');
    }
    final list = jsonDecode(resp.body);
    if (list is! List) return const [];
    return list.whereType<Map>().map((e) => ApiMix.fromJson(e.cast<String, dynamic>())).toList();
  }

  Future<List<ApiMix>> listPendingMixes({required String token}) async {
    final resp = await _client.get(
      _u('/mixes/pending'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('GET /mixes/pending failed (${resp.statusCode})');
    }
    final list = jsonDecode(resp.body);
    if (list is! List) return const [];
    return list.whereType<Map>().map((e) => ApiMix.fromJson(e.cast<String, dynamic>())).toList();
  }

  Future<ApiMix> uploadMix({
    required String token,
    required String title,
    required String description,
    required String genre,
    required bool isClean,
    required File audio,
    required File cover,
  }) async {
    final req = http.MultipartRequest('POST', _u('/mixes/upload'));
    req.headers['Authorization'] = 'Bearer $token';
    req.fields['title'] = title;
    req.fields['description'] = description;
    req.fields['genre'] = genre;
    req.fields['isClean'] = isClean ? 'true' : 'false';

    req.files.add(await http.MultipartFile.fromPath('audio', audio.path));
    req.files.add(await http.MultipartFile.fromPath('cover', cover.path));

    final streamed = await req.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw Exception('Upload failed (${streamed.statusCode}): $body');
    }

    return ApiMix.fromJson(jsonDecode(body) as Map<String, dynamic>);
  }

  Future<List<ApiMix>> listDjMixes({required String djId, String? token}) async {
    final headers = <String, String>{};
    final t = token?.trim() ?? '';
    if (t.isNotEmpty) headers['Authorization'] = 'Bearer $t';

    final resp = await _client.get(_u('/dj/$djId/mixes'), headers: headers);
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('GET /dj/$djId/mixes failed (${resp.statusCode})');
    }
    final list = jsonDecode(resp.body);
    if (list is! List) return const [];
    return list.whereType<Map>().map((e) => ApiMix.fromJson(e.cast<String, dynamic>())).toList();
  }

  Future<ApiMix> approveMix({required String token, required String mixId, required bool approve}) async {
    final resp = await _client.post(
      _u('/mixes/approve/$mixId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': approve ? 'approved' : 'rejected'}),
    );

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('POST /mixes/approve/$mixId failed (${resp.statusCode})');
    }
    return ApiMix.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  Future<String?> assistantPlay({required String query}) async {
    final q = query.trim();
    if (q.isEmpty) return null;

    final resp = await _client.post(
      _u('/assistant/play'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'query': q}),
    );

    if (resp.statusCode == 404) return null;
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      return null;
    }

    final json = jsonDecode(resp.body);
    if (json is! Map) return null;
    final audioUrl = (json['audioUrl'] as String?)?.trim();
    if (audioUrl == null || audioUrl.isEmpty) return null;
    return audioUrl;
  }

  Future<List<ApiAssistantLibraryItem>> listAssistantLibrary({required String token}) async {
    final resp = await _client.get(
      _u('/assistant/library'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('GET /assistant/library failed (${resp.statusCode})');
    }
    final list = jsonDecode(resp.body);
    if (list is! List) return const [];
    return list.whereType<Map>().map((e) => ApiAssistantLibraryItem.fromJson(e.cast<String, dynamic>())).toList();
  }

  Future<List<ApiAssistantLibraryItem>> listAssistantLibraryPublic() async {
    final resp = await _client.get(_u('/assistant/library/public'));
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('GET /assistant/library/public failed (${resp.statusCode})');
    }
    final list = jsonDecode(resp.body);
    if (list is! List) return const [];
    return list.whereType<Map>().map((e) => ApiAssistantLibraryItem.fromJson(e.cast<String, dynamic>())).toList();
  }

  Future<ApiAssistantLibraryItem> uploadAssistantLibraryAudio({
    required String token,
    required String title,
    required File audio,
    String keywordsCsv = '',
    bool isActive = true,
  }) async {
    final req = http.MultipartRequest('POST', _u('/assistant/library/upload'));
    req.headers['Authorization'] = 'Bearer $token';
    req.fields['title'] = title.trim();
    if (keywordsCsv.trim().isNotEmpty) req.fields['keywords'] = keywordsCsv.trim();
    req.fields['isActive'] = isActive ? 'true' : 'false';
    req.files.add(await http.MultipartFile.fromPath('audio', audio.path));

    final streamed = await req.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw Exception('Assistant upload failed (${streamed.statusCode}): $body');
    }
    return ApiAssistantLibraryItem.fromJson(jsonDecode(body) as Map<String, dynamic>);
  }

  void close() => _client.close();
}
