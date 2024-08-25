import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher_string.dart';
import 'package:yaml/yaml.dart';

class VersionResponse {
    VersionResponse(this.release);

    final Map release;

    String get version => release["tag_name"];

    Future<bool> isCurrentLatest() async {
        final currentVersion = loadYaml(await rootBundle.loadString("pubspec.yaml"))["version"];
        return version == currentVersion;
    }
}

Future<VersionResponse> checkForUpdates() async {
    final http.Response res = await http.get(Uri.https("api.github.com", "/repos/resucutie/localbooru/releases"));
    final List<dynamic> releases = jsonDecode(res.body);
    final latestRelease = releases.firstWhere((release) => release["prerelease"] == false && release["draft"] == false);
    // // spoofing for testing
    // return VersionResponse({
    //     "tag_name": "0.0.0"
    // });
    return VersionResponse(latestRelease);
}

class UpdateAvaiableDialog extends StatelessWidget {
    const UpdateAvaiableDialog({super.key, required this.ver});

    final VersionResponse ver;

    @override
    Widget build(BuildContext context) {
        return AlertDialog(
            title: const Text("Update avaiable"),
            content: Text("A new version is avaiable for download: ${ver.version}. Update now?"),
            actions: [
                TextButton(onPressed: Navigator.of(context).pop, child: const Text("Later")),
                TextButton(child: const Text("Yes"), 
                    onPressed: () {
                        launchUrlString("https://github.com/resucutie/localbooru/releases/");
                        Navigator.of(context).pop();
                    }
                ),
            ],
        );
    }
}