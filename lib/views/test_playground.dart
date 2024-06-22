import 'package:flutter/material.dart';
import 'package:localbooru/api/preset/index.dart';
import 'package:localbooru/components/counter.dart';

class TestPlaygroundScreen extends StatefulWidget {
    const TestPlaygroundScreen({super.key});

    @override
    State<TestPlaygroundScreen> createState() => _TestPlaygroundScreenState();
}

class _TestPlaygroundScreenState extends State<TestPlaygroundScreen> {
    @override
    Widget build(context) {
        return Scaffold(
            appBar: AppBar(
                title: const Text("Playground"),
            ),
            body: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    Center(
                        child: Wrap(
                            spacing: 8,
                            children: List.filled(5, Image.asset("assets/Screenshot_1009.webp", width: 64, fit: BoxFit.contain, filterQuality: FilterQuality.none,))
                        )
                    ),
                    const StyleCounter(number: 12345, display: "squares",),
                    const StyleCounter(number: 67890, display: "baba",),
                    FilledButton(
                        child: const Text("test webcrawing"),
                        onPressed: () async{
                            debugPrint("Testing with danbooru2");
                            await accurateGetWebsite(Uri.https("danbooru.donmai.us", "posts/7748685"));
                            debugPrint("Testing with moebooru");
                            await accurateGetWebsite(Uri.https("yande.re", "post/show/1178981"));
                            debugPrint("Testing with danbooru1"); // apparently dart defaults to https always, even with Uri.http
                            await accurateGetWebsite(Uri.http("behoimi.org", "post/show/653114/2b-blonde_hair-christmas-kaddi_cosplay-nier-nier_a"));
                            debugPrint("Testing with e621");
                            await accurateGetWebsite(Uri.parse("https://e926.net/posts/4869786"));
                            debugPrint("Testing with gelbooru 0.2.5");
                            await accurateGetWebsite(Uri.parse("https://gelbooru.com/index.php?page=post&s=view&id=10237422"));
                            debugPrint("Testing with gelbooru 0.2.0");
                            await accurateGetWebsite(Uri.parse("https://safebooru.org/index.php?page=post&s=view&id=5014759"));
                            debugPrint("Testing with furaffinity");
                            await accurateGetWebsite(Uri.parse("https://www.furaffinity.net/view/57099978/"));
                            debugPrint("Testing with deviantArt");
                            await accurateGetWebsite(Uri.parse("https://www.deviantart.com/pachunka/art/Cope-145564099"));
                            debugPrint("Testing with twitter");
                            await accurateGetWebsite(Uri.parse("https://x.com/ralfyneko/status/1801386308914528722"));
                        },
                    )
                ],
            )
        );
    }
}
