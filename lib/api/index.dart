library localbooru_api;

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:localbooru/utils/constants.dart';
import 'package:localbooru/utils/listeners.dart';
import 'package:localbooru/utils/tags.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

part 'readable.dart';
part 'writable.dart';

Booru? currentBooru;

Future<Booru> getCurrentBooru() async {
    if(currentBooru == null) {
        final prefs = await SharedPreferences.getInstance();
        final String? booruPath = prefs.getString("booruPath");
        debugPrint("Loaded booruPath with $booruPath");
        if (booruPath is! String) throw "Invalid or unset booru on settings";

        final String repoinfoPath = p.join(booruPath, "repoinfo.json");

        Map<String, dynamic> raw = jsonDecode(await File(repoinfoPath).readAsString());
        if(!isValidBooruModel(raw)) {
            debugPrint("Booru is not valid. Trying to fix it");
            writeSettings(booruPath, rebase(raw));
        }

        currentBooru = Booru(booruPath);
    }

    return currentBooru!;
}

Future<void> setBooru(String path) async {
    final prefs = await SharedPreferences.getInstance();
    currentBooru = null;
    prefs.setString("booruPath", path);
    booruUpdateListener.update();
}

Future<void> createDefaultBooruModel(String folderPath) async {
    File repoinfoFile = await File(p.join(folderPath, "repoinfo.json")).create(recursive: true);
    await repoinfoFile.writeAsString(jsonEncode(defaultFileInfoJson));
    await Directory(p.join(folderPath, "files")).create(recursive: true);
    await Directory(p.join(folderPath, "thumbnails")).create(recursive: true);
}

bool isValidBooruModel(Map<String, dynamic> raw) {
    return raw["files"] != null &&
        raw["specificTags"] != null;
}

// bool isValidBooruRepo (String path) async {

// }