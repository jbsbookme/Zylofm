import '../api/zylo_api.dart';
import '../api/admin_dashboard_api.dart';
import '../api/admin_dashboard_api_config.dart';
import 'admin_content_repository.dart';
import 'admin_content_models.dart';

/// BackendContentRepository
///
/// PASO 1: consume only approved mixes from the real backend.
/// We map them into the existing UI models (AdminContent/AdminDj/AdminMix)
/// so we don't have to rewrite the whole app UI at once.
class BackendContentRepository {
  final String baseUrl;
  final String dashboardBaseUrl;

  const BackendContentRepository({required this.baseUrl, this.dashboardBaseUrl = adminDashboardBaseUrl});

  Future<String?> assistantPlay(String query) async {
    final api = ZyloApi(baseUrl: baseUrl);
    try {
      return await api.assistantPlay(query: query);
    } finally {
      api.close();
    }
  }

  Future<AdminContent> load() async {
    final dashboard = AdminDashboardApi(baseUrl: dashboardBaseUrl);
    final api = ZyloApi(baseUrl: baseUrl);

    String radioUrl = '';
    try {
      radioUrl = (await dashboard.getRadioStreamUrl()) ?? '';
    } catch (_) {
      radioUrl = '';
    }

    try {
      final djs = await api.listDjs();
      final mixes = await api.listPublicMixes();

      final adminDjs = djs
          .map(
            (d) => AdminDj(
              id: d.id,
              name: d.displayName.isNotEmpty ? d.displayName : 'DJ',
              blurb: d.bio,
              location: d.location,
              genres: d.genres,
            ),
          )
          .toList(growable: false);

      final adminMixes = mixes
          .map(
            (m) => AdminMix(
              id: m.id,
              title: m.title,
              djId: m.djId,
              djName: m.djName ?? (adminDjs.firstWhere((d) => d.id == m.djId, orElse: () => const AdminDj(id: 'dj', name: 'DJ', blurb: '')).name),
              blurb: m.description,
              // Existing player expects an HLS URL field; for PASO 1 we play direct mp3/wav URLs.
              hlsUrl: m.audioUrl,
              coverUrl: m.coverUrl,
              durationSec: 0,
              featured: false,
            ),
          )
          .toList(growable: false);

      return AdminContent(
        version: 1,
        radio: AdminRadio(
          title: 'ZyloFM',
          streamUrl: radioUrl,
          tagline: '',
          badgeText: 'MIXES',
        ),
        djs: adminDjs,
        mixes: adminMixes,
        highlights: const AdminHighlights(heroMixId: null, featuredMixIds: [], featuredDjIds: []),
      );
    } catch (_) {
      // Backend down: fall back to dashboard (approved DJs) so the app stays usable locally.
      final approved = await dashboard.listApprovedDjs().catchError((_) => const <DashboardDj>[]);

      final adminDjs = approved
          .map(
            (d) => AdminDj(
              id: d.id,
              name: d.name.isNotEmpty ? d.name : 'DJ',
              blurb: d.bio ?? '',
              instagramUrl: d.instagram,
            ),
          )
          .toList(growable: false);

      // If we couldn't reach either backend nor dashboard (common on iPhone when LAN access is blocked),
      // load local seeded content so the UI remains visible and testable.
      if (adminDjs.isEmpty && radioUrl.trim().isEmpty) {
        try {
          return await const AdminContentRepository().load();
        } catch (_) {
          // ignore and fall back to empty content below
        }
      }

      return AdminContent(
        version: 1,
        radio: AdminRadio(
          title: 'ZyloFM',
          streamUrl: radioUrl,
          tagline: '',
          badgeText: 'RADIO • LIVE',
        ),
        djs: adminDjs,
        mixes: const <AdminMix>[],
        highlights: const AdminHighlights(heroMixId: null, featuredMixIds: [], featuredDjIds: []),
      );
    } finally {
      api.close();
      dashboard.close();
    }
  }
}
