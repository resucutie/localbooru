import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class VersionResponse {
    VersionResponse(this.release);

    final Map release;

    String get version => release["tag_name"];

    Future<bool> isCurrentLatest() async {
        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;
        return version == currentVersion;
    }
}

Future<VersionResponse> checkForUpdates() async {
    final http.Response res = await http.get(Uri.https("https://api.github.com/repos/resucutie/localbooru/releases"));
    final List<Map> releases = jsonDecode(res.body);
    final latestRelease = releases.firstWhere((release) => release["prerelease"] == false && release["draft"] == false);
    return VersionResponse(latestRelease);
}