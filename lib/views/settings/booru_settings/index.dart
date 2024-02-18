import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/components/headers.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
                ListTile(
                    subtitle: Text("Current booru path: ${widget.booru.path}")
                ),
            ],
        );
    }
}