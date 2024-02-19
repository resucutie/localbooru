import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/components/headers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';

class BooruSettings extends StatefulWidget {
    const BooruSettings({super.key, required this.prefs, required this.booru});

    final SharedPreferences prefs;
    final Booru booru;

    @override
    State<BooruSettings> createState() => _BooruSettingsState();
}

class _BooruSettingsState extends State<BooruSettings> {
    @override
    Widget build(BuildContext context) {
        return ListView(
            children: [
                const SmallThemedHeader("Tag types"),
                ListTile(
                    title: const Text("Manage tag types"),
                    subtitle: const Text("This is where you would set and unset tag types, in case you want, for example, make an artist tag a generic tag"),
                    leading: const Icon(Icons.label),
                    onTap: () => context.push("/settings/booru/tag_types"),
                ),
                const Divider(),
                const SmallThemedHeader("Other"),
                ListTile(
                    title: const Text("Rebase"),
                    subtitle: const Text("Reconstruct certain elements from the booru. Useful if you have some weird issue with it"),
                    leading: const Icon(Icons.refresh),
                    onTap: () async {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Rebasing...")));
                        await writeSettings(widget.booru.path, await widget.booru.rebaseRaw());
                        if (context.mounted) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();    
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Rebased")));
                        }
                    },
                ),
                ListTile(
                    title: const Text("Syncing"),
                    subtitle: const Text("This program does not offer syncing capabilities out of the box, but if you want to sync your computer storage, we recommend using Syncthing"),
                    leading: SvgPicture.asset("assets/syncthing.svg", width: 24, height: 24,),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () => launchUrlString("https://syncthing.net/"),
                ),
                ListTile(
                    subtitle: Text("Current booru path: ${widget.booru.path}")
                ),
            ],
        );
    }
}