@Tags(['import', 'identify', 'websites'])
library;

import 'package:localbooru/api/preset/index.dart';
import 'package:test/test.dart';

void main() {
    group("get website type: accurate", () {
        test("danbooru1", () async {
            final res = await accurateGetWebsite(Posts.danbooru1);
            expect(res, ServiceWebsites.danbooru1);
        });
        test("moebooru", () async {
            final res = await accurateGetWebsite(Posts.moebooru);
            expect(res, ServiceWebsites.danbooru1);
        });
        test("danbooru2", () async {
            final res = await accurateGetWebsite(Posts.danbooru2);
            expect(res, ServiceWebsites.danbooru2);
        });
        test("e621", () async {
            final res = await accurateGetWebsite(Posts.e621);
            expect(res, ServiceWebsites.e621);
        });
        test("gelbooru 0.2.5", () async {
            final res = await accurateGetWebsite(Posts.gelbooru025);
            expect(res, ServiceWebsites.gelbooru025);
        });
        test("gelbooru 0.2.0", () async {
            final res = await accurateGetWebsite(Posts.gelbooru020);
            expect(res, ServiceWebsites.gelbooru020);
        });
        test("gelbooru 0.1", () async {
            final res = await accurateGetWebsite(Posts.gelbooru01);
            expect(res, ServiceWebsites.gelbooru01);
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
    });
}

class Posts {
    static Uri danbooru1 = Uri.parse("http://behoimi.org/post/show/622798/ass-cosplay-dress-kaname_madoka-keika-kneehighs-na");
    static Uri moebooru = Uri.parse("https://konachan.com/post/show/369129/anila_-granblue_fantasy-blonde_hair-brown_eyes-fik");
    static Uri danbooru2 = Uri.parse("https://danbooru.donmai.us/posts/7933871");
    static Uri e621 = Uri.parse("https://e926.net/posts/4953753");
    static Uri gelbooru025 = Uri.parse("https://gelbooru.com/index.php?page=post&s=view&id=4546292&tags=rating%3Asafe");
    static Uri gelbooru020 = Uri.parse("https://safebooru.org/index.php?page=post&s=view&id=5104172");
    static Uri gelbooru01 = Uri.parse("http://behoimi.org/pool/show/47");
    static Uri twitter = Uri.parse("https://x.com/Winteriris42/status/1807092916935876809");
    static Uri furryaffinity = Uri.parse("https://www.furaffinity.net/view/53339919");
    static Uri deviantart = Uri.parse("http://fav.me/d2enxz7");
    static Uri instagram = Uri.parse("http://fav.me/d2enxz7");
}