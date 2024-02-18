import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/components/headers.dart';
import 'package:localbooru/utils/constants.dart';
import 'package:localbooru/utils/listeners.dart';
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
                ListTile(
                    subtitle: Text("Current booru path: ${widget.booru.path}")
                ),
            ],
        );
    }
}