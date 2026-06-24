class CountryHelper {
  static final Map<String, String> _countryCodeToName = {
    'uk': 'United Kingdom',
    'us': 'United States',
    'au': 'Australia',
    'ca': 'Canada',
    'ie': 'Ireland',
    'nz': 'New Zealand',
    'za': 'South Africa',
    'in': 'India',
    'qa': 'Qatar',
    'ae': 'UAE',
    'sa': 'Saudi Arabia',
    'fr': 'France',
    'de': 'Germany',
    'it': 'Italy',
    'es': 'Spain',
    'nl': 'Netherlands',
    'pt': 'Portugal',
    'se': 'Sweden',
    'no': 'Norway',
    'dk': 'Denmark',
    'fi': 'Finland',
    'ch': 'Switzerland',
    'at': 'Austria',
    'be': 'Belgium',
    'br': 'Brazil',
    'ar': 'Argentina',
    'mx': 'Mexico',
    'co': 'Colombia',
    'cl': 'Chile',
    'pe': 'Peru',
    'jp': 'Japan',
    'kr': 'South Korea',
    'cn': 'China',
    'hk': 'Hong Kong',
    'sg': 'Singapore',
    'my': 'Malaysia',
    'ph': 'Philippines',
    'th': 'Thailand',
    'id': 'Indonesia',
    'vn': 'Vietnam',
    'ru': 'Russia',
    'tr': 'Turkey',
    'eg': 'Egypt',
    'ma': 'Morocco',
    'ng': 'Nigeria',
    'ke': 'Kenya',
    'gh': 'Ghana',
    'dz': 'Algeria',
  };

  static final Map<String, String> _countryCodeToEmoji = {
    'uk': '🇬🇧',
    'us': '🇺🇸',
    'au': '🇦🇺',
    'ca': '🇨🇦',
    'ie': '🇮🇪',
    'nz': '🇳🇿',
    'za': '🇿🇦',
    'in': '🇮🇳',
    'qa': '🇶🇦',
    'ae': '🇦🇪',
    'sa': '🇸🇦',
    'fr': '🇫🇷',
    'de': '🇩🇪',
    'it': '🇮🇹',
    'es': '🇪🇸',
    'nl': '🇳🇱',
    'pt': '🇵🇹',
    'se': '🇸🇪',
    'no': '🇳🇴',
    'dk': '🇩🇰',
    'fi': '🇫🇮',
    'ch': '🇨🇭',
    'at': '🇦🇹',
    'be': '🇧🇪',
    'br': '🇧🇷',
    'ar': '🇦🇷',
    'mx': '🇲🇽',
    'co': '🇨🇴',
    'cl': '🇨🇱',
    'pe': '🇵🇪',
    'jp': '🇯🇵',
    'kr': '🇰🇷',
    'cn': '🇨🇳',
    'hk': '🇭🇰',
    'sg': '🇸🇬',
    'my': '🇲🇾',
    'ph': '🇵🇭',
    'th': '🇹🇭',
    'id': '🇮🇩',
    'vn': '🇻🇳',
    'ru': '🇷🇺',
    'tr': '🇹🇷',
    'eg': '🇪🇬',
    'ma': '🇲🇦',
    'ng': '🇳🇬',
    'ke': '🇰🇪',
    'gh': '🇬🇭',
    'dz': '🇩🇿',
  };

  static String? getCountryCode(String channelId) {
    // Usually formatted as "Name.cc" or "Name.cc@Quality"
    // So we can split by '.' and then split the second part by '@'
    final parts = channelId.toLowerCase().split('.');
    if (parts.length >= 2) {
      final codePart = parts[1].split('@').first;
      if (codePart.length == 2 && _countryCodeToName.containsKey(codePart)) {
        return codePart;
      }
    }
    return null;
  }

  static String getFlag(String channelId) {
    final code = getCountryCode(channelId);
    if (code != null) {
      return _countryCodeToEmoji[code] ?? '🏳️';
    }
    return '🏳️';
  }

  static String getName(String channelId) {
    final code = getCountryCode(channelId);
    if (code != null) {
      return _countryCodeToName[code] ?? 'Unknown';
    }
    return 'Unknown';
  }
}
