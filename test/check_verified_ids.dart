import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  test('Check verified ID format', () async {
    print('Fetching verified channel IDs...');
    final response = await http.get(
      Uri.parse('https://iptv-org.github.io/api/channels.json'),
    ).timeout(const Duration(seconds: 30));

    final List<dynamic> json = jsonDecode(response.body);
    final ids = json.map((c) => c['id']?.toString() ?? '').where((id) => id.isNotEmpty).toSet();
    
    print('Total verified IDs: ${ids.length}');
    
    // Check format - do they have @SD suffixes?
    final withAt = ids.where((id) => id.contains('@')).toList();
    final withoutAt = ids.where((id) => !id.contains('@')).toList();
    
    print('IDs with @ suffix: ${withAt.length}');
    print('IDs without @ suffix: ${withoutAt.length}');
    
    // Sample with @
    if (withAt.isNotEmpty) {
      print('\nSample IDs WITH @:');
      for (var id in withAt.take(10)) print('  "$id"');
    }
    
    // Sample without @
    print('\nSample IDs WITHOUT @:');
    for (var id in withoutAt.take(10)) print('  "$id"');
    
    // Check specific ones we know from M3U
    final testIds = ['ASpor.tr', 'ASpor.tr@SD', 'BandSports.br', 'BandSports.br@SD'];
    print('\nSpecific checks:');
    for (var id in testIds) {
      print('  "$id" in verified: ${ids.contains(id)}');
    }
  }, timeout: const Timeout(Duration(seconds: 60)));
}
