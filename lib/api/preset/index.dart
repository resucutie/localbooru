library preset;

import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/svg.dart';
import 'package:html/dom.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:localbooru/api/index.dart';
import 'package:html/parser.dart' show parse;
import 'package:localbooru/utils/get_meta_property.dart';
import 'package:localbooru/utils/listeners.dart';
import 'package:mime/mime.dart';
import 'package:string_validator/string_validator.dart';

part 'image.dart';
part 'collection.dart';
part 'autodownload/single/image_boards.dart';
part 'autodownload/single/generic.dart';
part 'autodownload/single/art_directed.dart';
part 'autodownload/single/other.dart';
part 'getter/index.dart';
part 'getter/website/accurate.dart';
part 'getter/collection.dart';

final presetCache = DefaultCacheManager();

abstract interface class Preset{
    Preset({this.key});

    Key? key;
}