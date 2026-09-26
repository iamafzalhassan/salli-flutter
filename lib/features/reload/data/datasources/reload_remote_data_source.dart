import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_paths.dart';
import '../models/recent_reload_model.dart';
import '../models/reload_catalog_model.dart';

class ReloadRemoteDataSource {
  final ApiClient _client;

  const ReloadRemoteDataSource(this._client);

  Future<ReloadCatalogModel> getCatalog(String operator) async => ReloadCatalogModel.fromJson(await _client.get(ApiPaths.reloadPlans, query: {'operator': operator}));

  Future<List<RecentReloadModel>> getRecentReloads() async => [for (final item in (await _client.get(ApiPaths.recentReloads))['items'] as List<dynamic>) RecentReloadModel.fromJson(item as Map<String, dynamic>)];
}
