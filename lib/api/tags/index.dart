library tag_manager;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:localbooru/api/index.dart';
import 'package:localbooru/utils/constants.dart';
import 'package:localbooru/utils/http_client.dart';
import 'package:localbooru/utils/misc.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'autotagger/index.dart';
part 'autotagger/models/index.dart';
part 'autotagger/models/hugging_face_spaces.dart';
part 'autotagger/models/danbooru_autotagger.dart';
part 'interfaces.dart';
part 'match.dart';
