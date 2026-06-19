class CategoryNormalizer {
  static const _map = {
    'sports': 'Sports',
    'sport': 'Sports',
    'football': 'Sports',
    'soccer': 'Sports',
    'movie': 'Movies',
    'films': 'Movies',
    'cinema': 'Movies',
  };

  static String normalize(String raw) {
    return _map[raw.trim().toLowerCase()] ?? raw.toLowerCase();
  }
}
