@Tags(['import', 'identify', 'collections'])
library;

import 'package:localbooru/api/preset/index.dart';
import 'package:test/test.dart';

void main() {
    group("check collections", () {
        test("danbooru1", () async {
            final res = await determineIfCollection(Uri.parse("http://behoimi.org/pool/show/47"));
            expect(res, true);
        });
        test("moebooru", () async {
            final res = await determineIfCollection(Uri.parse("https://konachan.com/pool/show/542"));
            expect(res, true);
        });
        test("danbooru2", () async {
            final res = await determineIfCollection(Uri.parse("https://danbooru.donmai.us/pools/14957"));
            expect(res, true);
        });
        test("e621", () async {
            final res = await determineIfCollection(Uri.parse("https://e926.net/pools/38721"));
            expect(res, true);
        });
        test("gelbooru 0.2.5", () async {
            final res = await determineIfCollection(Uri.parse("https://gelbooru.com/index.php?page=pool&s=show&id=64318"));
            expect(res, true);
        });
        test("gelbooru 0.2.0", () async {
            final res = await determineIfCollection(Uri.parse("https://safebooru.org/index.php?page=pool&s=show&id=694"));
            expect(res, true);
        });
    });
}