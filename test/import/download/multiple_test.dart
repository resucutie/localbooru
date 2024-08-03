@Tags(['import', 'download', 'multi'])
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:localbooru/utils/listeners.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:localbooru/api/preset/index.dart';

import '../../shared.dart';

final _env = Platform.environment;
final envTempDir = _env['TMPDIR'] ?? "";
final String kTemporaryPath = _env['TMPDIR'] == null ? '/tmp' : _env['TMPDIR']!;

const String kApplicationSupportPath = 'applicationSupportPath';
const String kDownloadsPath = 'downloadsPath';
const String kLibraryPath = 'libraryPath';
const String kApplicationDocumentsPath = 'applicationDocumentsPath';
const String kExternalCachePath = 'externalCachePath';
const String kExternalStoragePath = 'externalStoragePath';

void main() {
    void updateFunc() {
        debugPrint("Progress: ${importListener.progress}");
    }

    group("download", () {
        setUp(() {
            PathProviderPlatform.instance = PathProviderPlatformMock();
            importListener.addListener(updateFunc);
        });
        tearDown(() {
            importListener.removeListener(updateFunc);
        });
        test("e621", () async {
            final res = await VirtualPresetCollection.urlToPreset(Collections.e621.toString());
            expect(res, isA<VirtualPresetCollection>());
            expect(res.pages, isA<List<PresetImage>>());
            // expect(await res.image!.length(), isNot(0));
        }, tags: "e621");
    });
}

class PathProviderPlatformMock extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getTemporaryPath() async {
    return kTemporaryPath;
  }

  @override
  Future<String?> getApplicationSupportPath() async {
    return kApplicationSupportPath;
  }

  @override
  Future<String?> getLibraryPath() async {
    return kLibraryPath;
  }

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return kApplicationDocumentsPath;
  }

  @override
  Future<String?> getExternalStoragePath() async {
    return kExternalStoragePath;
  }

  @override
  Future<List<String>?> getExternalCachePaths() async {
    return <String>[kExternalCachePath];
  }

  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async {
    return <String>[kExternalStoragePath];
  }

  @override
  Future<String?> getDownloadsPath() async {
    return kDownloadsPath;
  }
}