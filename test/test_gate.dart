import 'package:stream_vault/data/services/m3u_service.dart';
import 'package:stream_vault/data/services/registry_service.dart';
import 'package:stream_vault/core/constants/app_constants.dart';

void main() async {
  try {
    final reg = RegistryService();
    final m3u = M3uService();
    
    print('Fetching verified IDs...');
    final vIds = await reg.fetchVerifiedIds();
    print('Verified IDs: ${vIds.length}');
    
    print('Fetching Sports M3U...');
    final s = await m3u.fetchCategory(AppConstants.sportsM3uUrl);
    print('Sports: ${s.length}');
    
    int matched = 0;
    for (var c in s) {
      if (vIds.contains(c.attributes['tvg-id'])) {
        matched++;
      }
    }
    print('Matched: $matched');
  } catch (e, stack) {
    print('Error: $e\n$stack');
  }
}
