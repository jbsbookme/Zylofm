import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'admin_content_models.dart';

class AdminContentRepository {
  final String assetPath;

  const AdminContentRepository({
    this.assetPath = 'assets/admin/content.json',
  });

  Future<AdminContent> load() async {
    final text = await rootBundle.loadString(assetPath);
    final jsonMap = jsonDecode(text) as Map<String, dynamic>;
    return AdminContent.fromJson(jsonMap);
  }
}
