import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

String? getWebsite(Uri uri) {
    if( uri.host.endsWith("behoimi.org") || // literally the only site running danbooru 1 on the planet
        uri.host.endsWith("konachan.com") || uri.host.endsWith("yande.re") // moebooru
    ) return "danbooru1";
    if(uri.host.endsWith("donmai.us")) return "danbooru2";
    if(uri.host.endsWith("e621.net") || uri.host.endsWith("e926.net")) return "e621";
    if( uri.host.endsWith("gelbooru.com") || //0.2.5
        uri.host.endsWith("safebooru.org") || uri.host.endsWith("rule34.xxx") || uri.host.endsWith("xbooru.com") // 0.2.0
    ) return "gelbooru2";
    if( uri.host == "twitter.com" || uri.host == "x.com" ||
        uri.host.endsWith("fixupx.com") || uri.host.endsWith("fivx.com")
    ) return "twitter";
    if(uri.host.endsWith("furaffinity.net")) return "furaffinity";
    if(uri.host.endsWith("deviantart.com") || uri.host == "fav.me") return "deviantart";
    if(uri.host.endsWith("instagram.com") || uri.host.endsWith("ddinstagram.com")) return "instagram";
    return null; // none
}

String? getWebsiteFormalType(Uri uri) {
    return switch (getWebsite(uri)) {
        "danbooru1" || "danbooru2" => "Danbooru",
        "e621" => "e621",
        "gelbooru2" => "Gelbooru",
        "twitter" => "Twitter",
        "furaffinity" => "FurAffinity",
        "deviantart" => "DeviantArt",
        _ => null
    };
}

Widget? getWebsiteIcon(Uri uri, {Color? color}) {
    return switch (getWebsite(uri)) {
        "danbooru1" || "danbooru2" => color == null
            ? SvgPicture.asset("assets/websites/danbooru.svg", width: 24, height: 24, color: color,)
            : SvgPicture.asset("assets/websites/danbooru-monochrome.svg", width: 24, height: 24, color: color,),
        "e621" => SvgPicture.asset("assets/websites/e621.svg", width: 24, height: 24, color: color,),
        "gelbooru2" => SvgPicture.asset("assets/websites/gelbooru.svg", width: 24, height: 24, color: color ?? Colors.blue,),
        "twitter" => SvgPicture.asset("assets/websites/twitter.svg", width: 24, height: 24, color: color,),
        "furaffinity" => Icon(Icons.pets, color: color,),
        "deviantart" => SvgPicture.asset("assets/websites/deviantart.svg", width: 24, height: 24, color: color,),
        _ => null,
    };
}