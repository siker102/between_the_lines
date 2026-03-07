import 'dart:convert';
import 'dart:io';

bool isCompatible(String constraint, String current) {
  if (constraint.isEmpty) return true;
  // A naive check for our specific case:
  // if constraint contains >=3.11.0, and our current is 3.8.1, it's not compatible.
  // We'll just look for constraints that don't start with something higher than 3.8.
  if (constraint.contains('>=3.11') ||
      constraint.contains('>=3.12') ||
      constraint.contains('>=3.9') ||
      constraint.contains('>=3.10')) {
    return false;
  }
  return true;
}

void main() async {
  final packages = ['flame', 'flame_audio', 'flame_test'];
  for (var pkg in packages) {
    var res = await HttpClient().getUrl(Uri.parse('https://pub.dev/api/packages/$pkg'));
    var req = await res.close();
    var body = await req.transform(utf8.decoder).join();
    var data = jsonDecode(body);
    var versions = data['versions'] as List;
    print('--- $pkg ---');
    for (var v in versions.reversed) {
      var dSdk = v['pubspec']?['environment']?['sdk'];
      if (dSdk != null && isCompatible(dSdk, '3.8.1')) {
        print('HIGHEST COMPATIBLE: ${v["version"]} (SDK: $dSdk)');
        break;
      }
    }
  }
}
