import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/components/headers.dart';
import 'package:path/path.dart' as p;
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
    late Future<List<bool>> _hideMedia;

    void setHideMedia() {
        _hideMedia = Future.wait([
            File(p.join(widget.booru.path, "files", ".nomedia")).exists(),
            File(p.join(widget.booru.path, "thumbnails", ".nomedia")).exists()
        ]);
    }

    @override
    void initState() {
        super.initState();
        setHideMedia();
    }

    @override
    Widget build(BuildContext context) {
        return ListView(
            children: [
                const SmallHeader("Elements"),
                ListTile(
                    title: const Text("Tag types"),
                    subtitle: const Text("Remove or create tag types"),
                    leading: const Icon(Icons.label),
                    onTap: () => context.push("/settings/booru/tag_types"),
                ),
                ListTile(
                    title: const Text("Collections"),
                    subtitle: const Text("Manage existing collections"),
                    leading: const Icon(Icons.photo_library),
                    onTap: () => context.push("/settings/booru/collections"),
                ),
                const SmallHeader("Other"),
                ListTile(
                    title: const Text("Rebase"),
                    subtitle: const Text("Reconstruct certain elements from the booru. Useful if you have some weird issue with it"),
                    leading: const Icon(Icons.refresh),
                    onTap: () async {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Rebasing...")));
                        final raw = await widget.booru.rebaseRaw();
                        await writeSettings(widget.booru.path, raw);
                        if (context.mounted) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();    
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Rebased")));
                        }
                    },
                ),
                FutureBuilder(
                    future: _hideMedia,
                    builder: (context, snapshot) => SwitchListTile(
                        title: const Text("Hide images from gallery"),
                        secondary: const Icon(Icons.hide_image_outlined),
                        value: snapshot.hasData ? snapshot.data!.every((e) => e == true) : false,
                        onChanged: snapshot.hasData ? (value) async {
                            final File nomediaFiles = File(p.join(widget.booru.path, "files", ".nomedia"));
                            final File nomediaThumbnails = File(p.join(widget.booru.path, "thumbnails", ".nomedia"));
                            if(value) {
                                await nomediaFiles.create();
                                await nomediaThumbnails.create();
                            } else {
                                await nomediaFiles.delete();
                                await nomediaThumbnails.delete();
                            }
                            setState(setHideMedia);
                        } : null
                    ),
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