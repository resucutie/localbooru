library tag_manager;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:localbooru/api/index.dart';
import 'package:localbooru/utils/misc.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:collection/collection.dart';

part 'autotag.dart';
part 'interfaces.dart';
part 'match.dart';
