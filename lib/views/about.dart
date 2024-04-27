import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:yaml/yaml.dart';

class AboutScreen extends StatefulWidget{
    const AboutScreen({super.key});

    @override
    State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen>{
    @override
    Widget build(BuildContext context) {
        return Scaffold (
            appBar: AppBar(),
            body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                    child: Wrap(
                        direction: Axis.vertical,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                            SvgPicture.asset("assets/brand/rounded-icon.svg", width: 128, height: 128,),
                            const SizedBox(height: 8,),
                            const Text("LocalBooru", style: TextStyle(
                                fontSize: 36
                            )),
                            FutureBuilder<Map<String, dynamic>>(
                                future: (() async => {"yaml": await rootBundle.loadString("pubspec.yaml"), "packageInfo": await PackageInfo.fromPlatform()})(),
                                builder: (context, snapshot) {
                                    String version = "Unknown";
                                    if (snapshot.hasData) {
                                        var yaml = loadYaml(snapshot.data!["yaml"]);
                                        PackageInfo packageInfo = snapshot.data!["packageInfo"];
                                        version = "${packageInfo.version} \"${yaml["localbooru_codename"]}\"";
                                    }
                            
                                    return Text(version, style: const TextStyle(fontSize: 14),);
                                },
                            ),
                            const Text("Made with love by A user"),
                            const SizedBox(height: 32),
                            Row(
                                children: [
                                    IconButton(
                                        icon: SvgPicture.asset("assets/github.svg", width: 24, height: 24, color: Theme.of(context).hintColor),
                                        onPressed: () => launchUrlString("https://github.com/resucutie/localbooru"),
                                    ),
                                ],
                            )
                        ]
                    )
                ),
            )
        );
    }
}
