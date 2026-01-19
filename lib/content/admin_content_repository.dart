import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import 'admin_content_models.dart';

class AdminContentRepository {
  final String assetPath;
  final String? remoteUrl;

  const AdminContentRepository({
    this.assetPath = 'assets/admin/content.json',
    this.remoteUrl,
  });

  Future<AdminContent> load() async {
    final remote = remoteUrl?.trim();
    if (remote != null && remote.isNotEmpty) {
      final remoteContent = await _tryLoadRemote(remote);
      if (remoteContent != null) return remoteContent;
    }

    final text = await rootBundle.loadString(assetPath);
    final jsonMap = jsonDecode(text) as Map<String, dynamic>;
    return AdminContent.fromJson(jsonMap);
  }

  Future<AdminContent?> _tryLoadRemote(String url) async {
    try {
      final uri = Uri.parse(url);
      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 6));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
      return AdminContent.fromJson(jsonMap);
    } catch (_) {
      return null;
    }
  }
}
