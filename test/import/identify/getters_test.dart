@Tags(['import', 'identify', 'websites'])
library;

import 'package:localbooru/api/preset/index.dart';
import 'package:test/test.dart';

import '../../shared.dart';

void main() {
    group("get website type: accurate", () {
        test("danbooru1", () async {
            final res = await accurateGetWebsite(Posts.danbooru1);
            expect(res, BooruWebsites.danbooru1);
        });
        test("moebooru", () async {
            final res = await accurateGetWebsite(Posts.moebooru);
            expect(res, BooruWebsites.danbooru1);
        });
        test("danbooru2", () async {
            final res = await accurateGetWebsite(Posts.danbooru2);
            expect(res, BooruWebsites.danbooru2);
        });
        test("e621", () async {
            final res = await accurateGetWebsite(Posts.e621);
            expect(res, BooruWebsites.e621);
        });
        test("gelbooru 0.2.5", () async {
            final res = await accurateGetWebsite(Posts.gelbooru025);
            expect(res, BooruWebsites.gelbooru025);
        });
        test("gelbooru 0.2.0", () async {
            final res = await accurateGetWebsite(Posts.gelbooru020);
            expect(res, BooruWebsites.gelbooru020);
        });
        test("gelbooru 0.1", () async {
            final res = await accurateGetWebsite(Posts.gelbooru01);
            expect(res, BooruWebsites.gelbooru01);
        }, skip: "Not implemented");
        test("twitter", () async {
            final res = await accurateGetWebsite(Posts.twitter);
            expect(res, ServiceWebsites.twitter);
        });
        test("furaffinity", () async {
            final res = await accurateGetWebsite(Posts.furryaffinity);
            expect(res, ServiceWebsites.furAffinity);
        });
        test("instagram", () async {
            final res = await accurateGetWebsite(Posts.instagram);
            expect(res, ServiceWebsites.instagram);
        }, skip: "Not implemented");
        test("philomena", () async {
            final res = await accurateGetWebsite(Posts.philomena);
            expect(res, BooruWebsites.philomena);
        });
    });
}