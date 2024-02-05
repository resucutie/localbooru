library localbooru_api;

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
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

typedef BooruWidgetBuilder = Widget Function(BuildContext context, Booru booru);
class BooruLoader extends StatelessWidget {
    const BooruLoader({super.key, required this.builder});

    final BooruWidgetBuilder builder;
    
    @override
    Widget build(BuildContext context) {
        return FutureBuilder<Booru>(
            future: getCurrentBooru(),
            builder: (context, AsyncSnapshot<Booru> snapshot) {
                if(snapshot.hasData) {
                    return builder(context, snapshot.data!);
                } else if(snapshot.hasError) {
                    throw snapshot.error!;
                }
                return const Center(child: CircularProgressIndicator());
            }
        );
    }   
}

typedef BooruImageWidgetBuilder = Widget Function(BuildContext context, BooruImage image);
class BooruImageLoader extends StatelessWidget {
    const BooruImageLoader({super.key, required this.builder, required this.booru, required this.id});

    final Booru booru;
    final String id;

    final BooruImageWidgetBuilder builder;
    
    @override
    Widget build(BuildContext context) {
        return FutureBuilder<BooruImage>(
            future: booru.getImage(id),
            builder: (context, AsyncSnapshot<BooruImage> snapshot) {
                if(snapshot.hasData) {
                    return builder(context, snapshot.data!);
                } else if(snapshot.hasError) {
                    throw snapshot.error!;
                }
                return const Center(child: CircularProgressIndicator());
            }
        );
    }   
}

// bool isValidBooruRepo (String path) async {

// }