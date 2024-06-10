import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

abstract class Websites {}
enum ServiceWebsites implements Websites {danbooru1, danbooru2, e621, gelbooru020, gelbooru025, gelbooru01, twitter, furAffinity, deviantArt, instagram}
enum GenericWebsites implements Websites {file}

Websites? getWebsiteByURL(Uri uri) {
    if( uri.host.endsWith("behoimi.org") || // literally the only site running danbooru 1 on the planet
        uri.host.endsWith("konachan.com") || uri.host.endsWith("yande.re") // moebooru
    ) return ServiceWebsites.danbooru1;
    if(uri.host.endsWith("donmai.us")) return ServiceWebsites.danbooru2;
    if(uri.host.endsWith("e621.net") || uri.host.endsWith("e926.net")) return ServiceWebsites.e621;
    if(uri.host.endsWith("gelbooru.com")) return ServiceWebsites.gelbooru025;
    if(uri.host.endsWith("safebooru.org") || uri.host.endsWith("rule34.xxx") || uri.host.endsWith("xbooru.com")) return ServiceWebsites.gelbooru020;
    if( uri.host == "twitter.com" || uri.host == "x.com" ||
        uri.host.endsWith("fixupx.com") || uri.host.endsWith("fivx.com") || uri.host.endsWith("fxtwitter.com") || uri.host.endsWith("vxtwitter.com")
    ) return ServiceWebsites.twitter;
    if(uri.host.endsWith("furaffinity.net")) return ServiceWebsites.furAffinity;
    if(uri.host.endsWith("deviantart.com") || uri.host == "fav.me") return ServiceWebsites.deviantArt;
    if(uri.host.endsWith("instagram.com") || uri.host.endsWith("ddinstagram.com")) return ServiceWebsites.instagram;
    return null; // none
}

String getWebsiteName(Websites websites) {
    return switch (websites) {
        ServiceWebsites.danbooru1 => "Moebooru",
        ServiceWebsites.danbooru2 => "Danbooru",
        ServiceWebsites.e621 => "e621",
        ServiceWebsites.gelbooru025 || ServiceWebsites.gelbooru020 || ServiceWebsites.gelbooru01 => "Gelbooru",
        ServiceWebsites.twitter => "Twitter",
        ServiceWebsites.furAffinity => "FurAffinity",
        ServiceWebsites.deviantArt => "DeviantArt",
        ServiceWebsites.instagram => "Instagram",
        _ => "Unknown"
    };
}

Widget? getWebsiteIcon(Websites website, {Color? color}) {
    return switch (website) {
        ServiceWebsites.danbooru1 || ServiceWebsites.danbooru2
            => color == null
                ? SvgPicture.asset("assets/websites/danbooru.svg", width: 24, height: 24, color: color,)
                : SvgPicture.asset("assets/websites/danbooru-monochrome.svg", width: 24, height: 24, color: color,),
        ServiceWebsites.e621 => SvgPicture.asset("assets/websites/e621.svg", width: 24, height: 24, color: color,),
        ServiceWebsites.gelbooru01 || ServiceWebsites.gelbooru020 || ServiceWebsites.gelbooru025
            => SvgPicture.asset("assets/websites/gelbooru.svg", width: 24, height: 24, color: color ?? Colors.blue,),
        ServiceWebsites.twitter => SvgPicture.asset("assets/websites/twitter.svg", width: 24, height: 24, color: color,),
        ServiceWebsites.furAffinity => Icon(Icons.pets, color: color,),
        ServiceWebsites.deviantArt => SvgPicture.asset("assets/websites/deviantart.svg", width: 24, height: 24, color: color,),
        _ => null,
    };
}