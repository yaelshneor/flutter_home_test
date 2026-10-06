import '../../domain/repositories/favorite_repository.dart';
import '../datasources/favorite_local_datasource.dart';

class FavoriteRepositoryImpl implements FavoriteRepository {
  FavoriteRepositoryImpl({required this.localDataSource});

  final FavoriteLocalDataSource localDataSource;

  @override
  Future<String?> getFavoriteUrl() {
    return localDataSource.getFavoriteUrl();
  }

  @override
  Future<void> saveFavoriteUrl(String url) {
    return localDataSource.saveFavoriteUrl(url);
  }

  @override
  Future<void> clearFavorite() {
    return localDataSource.clearFavorite();
  }
}
