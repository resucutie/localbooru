@Tags(['import', 'identify', 'multi'])
library;

import 'package:localbooru/api/preset/index.dart';
import 'package:test/test.dart';

import '../../shared.dart';

void main() {
    group("check collections", () {
        test("danbooru1", () async {
            final res = await determineIfCollection(Collections.danbooru1);
            expect(res, true);
        });
        test("moebooru", () async {
            final res = await determineIfCollection(Collections.moebooru);
            expect(res, true);
        });
        test("danbooru2", () async {
            final res = await determineIfCollection(Collections.danbooru2);
            expect(res, true);
        });
        test("e621", () async {
            final res = await determineIfCollection(Collections.e621);
            expect(res, true);
        });
        test("gelbooru 0.2.5", () async {
            final res = await determineIfCollection(Collections.gelbooru025);
            expect(res, true);
        });
        test("gelbooru 0.2.0", () async {
            final res = await determineIfCollection(Collections.gelbooru020);
            expect(res, true);
        });
    });
}