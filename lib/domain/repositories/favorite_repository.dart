abstract interface class FavoriteRepository {
  Future<String?> getFavoriteUrl();

  Future<void> saveFavoriteUrl(String url);

  Future<void> clearFavorite();
}
