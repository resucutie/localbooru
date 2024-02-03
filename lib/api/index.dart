library localbooru_api;

import 'dart:io';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

part "class.dart";

Booru? currentBooru;

Future<Booru> getCurrentBooru() async {
    if(currentBooru == null) {
        final prefs = await SharedPreferences.getInstance();
        final String? booruPath = prefs.getString("booruPath");
        debugPrint("booruPath $booruPath");
        if (booruPath is! String) throw "Invalid or unset booru on settings";
        currentBooru = Booru(booruPath);
    }
    return currentBooru as Booru;
}

void setBooru(String path) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("booruPath", path);
    debugPrint(prefs.getString("booruPath"));
}

// bool isValidBooruRepo (String path) async {

// }