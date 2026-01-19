import 'package:flutter/foundation.dart';

@immutable
class AdminRadio {
  final String title;
  final String streamUrl;
  final String? coverUrl;
  final String tagline;
  final String badgeText;

  const AdminRadio({
    required this.title,
    required this.streamUrl,
    required this.tagline,
    required this.badgeText,
    this.coverUrl,
  });

  factory AdminRadio.fromJson(Map<String, dynamic> json) {
    return AdminRadio(
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? (json['title'] as String).trim()
          : 'ZyloFM',
      streamUrl: (json['streamUrl'] as String? ?? '').trim(),
      coverUrl: (json['coverUrl'] as String?)?.trim(),
      tagline: (json['tagline'] as String?)?.trim() ?? '',
      badgeText: (json['badgeText'] as String?)?.trim().isNotEmpty == true
          ? (json['badgeText'] as String).trim()
          : 'RADIO • LIVE',
    );
  }
}

@immutable
class AdminDj {
  final String id;
  final String name;
  final String blurb;
  final String? avatarUrl;
  final String? instagramUrl;
  final String? tiktokUrl;
  final String? soundcloudUrl;
  final String? youtubeUrl;
  final List<String> latestMixIds;
  final List<String> popularMixIds;

  const AdminDj({
    required this.id,
    required this.name,
    required this.blurb,
    this.avatarUrl,
    this.instagramUrl,
    this.tiktokUrl,
    this.soundcloudUrl,
    this.youtubeUrl,
    this.latestMixIds = const <String>[],
    this.popularMixIds = const <String>[],
  });

  factory AdminDj.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as String? ?? '').trim();
    final name = (json['name'] as String? ?? '').trim();

    String? optUrl(String key) {
      final raw = (json[key] as String?)?.trim();
      return (raw != null && raw.isNotEmpty) ? raw : null;
    }

    List<String> optIdList(String key) {
      final raw = json[key];
      if (raw is List) {
        return raw.whereType<String>().map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      }
      return const <String>[];
    }

    return AdminDj(
      id: id.isNotEmpty ? id : name.toLowerCase().replaceAll(' ', '_'),
      name: name.isNotEmpty ? name : 'DJ',
      blurb: (json['blurb'] as String?)?.trim() ?? '',
      avatarUrl: (json['avatarUrl'] as String?)?.trim(),
      instagramUrl: optUrl('instagramUrl'),
      tiktokUrl: optUrl('tiktokUrl'),
      soundcloudUrl: optUrl('soundcloudUrl'),
      youtubeUrl: optUrl('youtubeUrl'),
      latestMixIds: optIdList('latestMixIds'),
      popularMixIds: optIdList('popularMixIds'),
    );
  }
}

@immutable
class AdminMix {
  final String id;
  final String title;
  final String djId;
  final String djName;
  final String blurb;
  final String hlsUrl;
  final String? coverUrl;
  final int durationSec;
  final bool featured;

  const AdminMix({
    required this.id,
    required this.title,
    required this.djId,
    required this.djName,
    required this.blurb,
    required this.hlsUrl,
    required this.durationSec,
    required this.featured,
    this.coverUrl,
  });

  factory AdminMix.fromJson(Map<String, dynamic> json, {required Map<String, AdminDj> djById}) {
    final id = (json['id'] as String? ?? '').trim();
    final title = (json['title'] as String? ?? '').trim();
    final djId = (json['djId'] as String? ?? '').trim();
    final djName = (json['djName'] as String?)?.trim();

    final resolvedDjName =
        djName?.isNotEmpty == true ? djName! : (djById[djId]?.name ?? 'DJ');

    return AdminMix(
      id: id.isNotEmpty ? id : title.toLowerCase().replaceAll(' ', '_'),
      title: title.isNotEmpty ? title : 'Mix',
      djId: djId,
      djName: resolvedDjName,
      blurb: (json['blurb'] as String?)?.trim() ?? '',
      hlsUrl: (json['hlsUrl'] as String? ?? '').trim(),
      coverUrl: (json['coverUrl'] as String?)?.trim(),
      durationSec: (json['durationSec'] as num?)?.toInt() ?? 0,
      featured: json['featured'] == true,
    );
  }

  String get formattedDuration {
    final total = durationSec <= 0 ? 0 : durationSec;
    final minutes = total ~/ 60;
    final seconds = total % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

@immutable
class AdminHighlights {
  final String? heroMixId;
  final List<String> featuredMixIds;
  final List<String> featuredDjIds;

  const AdminHighlights({
    required this.heroMixId,
    required this.featuredMixIds,
    required this.featuredDjIds,
  });

  factory AdminHighlights.fromJson(Map<String, dynamic> json) {
    List<String> listFromKey(String key) {
      final raw = json[key];
      if (raw is List) {
        return raw.whereType<String>().map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      }
      return const <String>[];
    }

    final hero = (json['heroMixId'] as String?)?.trim();
    return AdminHighlights(
      heroMixId: hero?.isNotEmpty == true ? hero : null,
      featuredMixIds: listFromKey('featuredMixIds'),
      featuredDjIds: listFromKey('featuredDjIds'),
    );
  }
}

@immutable
class AdminContent {
  final int version;
  final AdminRadio radio;
  final List<AdminDj> djs;
  final List<AdminMix> mixes;
  final AdminHighlights highlights;

  const AdminContent({
    required this.version,
    required this.radio,
    required this.djs,
    required this.mixes,
    required this.highlights,
  });

  factory AdminContent.fromJson(Map<String, dynamic> json) {
    final version = (json['version'] as num?)?.toInt() ?? 1;
    final radio = AdminRadio.fromJson((json['radio'] as Map?)?.cast<String, dynamic>() ?? const {});

    final djsRaw = (json['djs'] as List?) ?? const [];
    final djs = djsRaw
        .whereType<Map>()
        .map((e) => AdminDj.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);

    final djById = {for (final dj in djs) dj.id: dj};

    final mixesRaw = (json['mixes'] as List?) ?? const [];
    final mixes = mixesRaw
        .whereType<Map>()
        .map((e) => AdminMix.fromJson(e.cast<String, dynamic>(), djById: djById))
        .toList(growable: false);

    final highlightsJson = (json['highlights'] as Map?)?.cast<String, dynamic>() ?? const {};
    final highlights = AdminHighlights.fromJson(highlightsJson);

    return AdminContent(
      version: version,
      radio: radio,
      djs: djs,
      mixes: mixes,
      highlights: highlights,
    );
  }

  List<AdminMix> get featuredMixes {
    final featuredByFlag = mixes.where((m) => m.featured).toList(growable: false);
    if (featuredByFlag.isNotEmpty) return featuredByFlag;

    final featuredIds = highlights.featuredMixIds.toSet();
    if (featuredIds.isNotEmpty) {
      return mixes.where((m) => featuredIds.contains(m.id)).toList(growable: false);
    }

    return mixes.take(6).toList(growable: false);
  }

  AdminMix? mixForDj(String djId) {
    for (final m in mixes) {
      if (m.djId == djId) return m;
    }
    return null;
  }
}
