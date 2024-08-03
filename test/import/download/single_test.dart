@Tags(['import', 'download', 'single'])
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
    // group("test", () {
    //     setUp(() async {
    //         PathProviderPlatform.instance = FakePathProviderPlatform();
    //     });
    //     test("download a file", () async {
    //         final file = await downloadFile(Uri.parse("https://safebooru.org//samples/4619/sample_631e22a16c93c5b6fc9bd29fb18fe380091fd4df.jpg?5109590"));
    //         expect(file is File, true);
    //         expect(await file.length() == 0, false);
    //     });
    // });

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
        test("danbooru1", () async {
            final res = await PresetImage.urlToPreset(Posts.danbooru1.toString(), accurate: true);
            expect(res, isA<PresetImage>());
            expect(res.image, isA<File>());
            expect(await res.image!.length(), isNot(0));
        });
        test("moebooru", () async {
            final res = await PresetImage.urlToPreset(Posts.moebooru.toString(), accurate: true);
            expect(res, isA<PresetImage>());
            expect(res.image, isA<File>());
            expect(await res.image!.length(), isNot(0));
        });
        test("danbooru2", () async {
            final res = await PresetImage.urlToPreset(Posts.danbooru2.toString(), accurate: true);
            expect(res, isA<PresetImage>());
            expect(res.image, isA<File>());
            expect(await res.image!.length(), isNot(0));
        });
        test("e621", () async {
            final res = await PresetImage.urlToPreset(Posts.e621.toString(), accurate: true);
            expect(res, isA<PresetImage>());
            expect(res.image, isA<File>());
            expect(await res.image!.length(), isNot(0));
        });
        test("gelbooru 0.2.5", () async {
            final res = await PresetImage.urlToPreset(Posts.gelbooru025.toString(), accurate: true);
            expect(res, isA<PresetImage>());
            expect(res.image, isA<File>());
            expect(await res.image!.length(), isNot(0));
        });
        test("gelbooru 0.2.0", () async {
            final res = await PresetImage.urlToPreset(Posts.gelbooru020.toString(), accurate: true);
            expect(res, isA<PresetImage>());
            expect(res.image, isA<File>());
            expect(await res.image!.length(), isNot(0));
        });
        test("gelbooru 0.1", () async {
            final res = await PresetImage.urlToPreset(Posts.gelbooru01.toString(), accurate: true);
            expect(res, isA<PresetImage>());
            expect(res.image, isA<File>());
            expect(await res.image!.length(), isNot(0));
        }, skip: "Not implemented");
        test("twitter", () async {
            final res = await PresetImage.urlToPreset(Posts.twitter.toString(), accurate: true);
            expect(res, isA<PresetImage>());
            expect(res.image, isA<File>());
            expect(await res.image!.length(), isNot(0));
        });
        test("furaffinity", () async {
            final res = await PresetImage.urlToPreset(Posts.furryaffinity.toString(), accurate: true);
            expect(res, isA<PresetImage>());
            expect(res.image, isA<File>());
            expect(await res.image!.length(), isNot(0));
        });
        test("instagram", () async {
            final res = await PresetImage.urlToPreset(Posts.instagram.toString(), accurate: true);
            expect(res, isA<PresetImage>());
            expect(res.image, isA<File>());
            expect(await res.image!.length(), isNot(0));
        }, skip: "Not implemented");
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