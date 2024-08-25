import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
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
                            FutureBuilder<String>(
                                future: rootBundle.loadString("pubspec.yaml"),
                                builder: (context, snapshot) {
                                    String version = "Unknown";
                                    if (snapshot.hasData) {
                                        var yaml = loadYaml(snapshot.data!);
                                        version = "${yaml["version"]} \"${yaml["localbooru_codename"]}\"";
                                    }
                            
                                    return Text(version, style: const TextStyle(fontSize: 14),);
                                },
                            ),
                            const Text("Made with love by A user"),
                            const SizedBox(height: 32),
                            Wrap(
                                spacing: 8,
                                children: [
                                    IconButton(
                                        icon: SvgPicture.asset("assets/github.svg", width: 24, height: 24, color: Theme.of(context).hintColor),
                                        onPressed: () => launchUrlString("https://github.com/resucutie/localbooru"),
                                    ),
                                    IconButton(
                                        icon: SvgPicture.asset("assets/discord.svg", width: 24, height: 24, color: Theme.of(context).hintColor),
                                        onPressed: () => launchUrlString("https://discord.gg/mYuUKunj"),
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
