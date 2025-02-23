// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/api/preset/index.dart';
import 'package:localbooru/components/counter.dart';
import 'package:localbooru/components/multi_image_display.dart';

class TestPlaygroundScreen extends StatefulWidget {
    const TestPlaygroundScreen({super.key});

    @override
    State<TestPlaygroundScreen> createState() => _TestPlaygroundScreenState();
}

class _TestPlaygroundScreenState extends State<TestPlaygroundScreen> {
    void testAccurateIdentification() async {
        final Map<String, Uri> websites = {
            "danbooru 2": Uri.https("danbooru.donmai.us", "posts/7748685"),
            "moebooru": Uri.https("yande.re", "post/show/1178981"),
            "danbooru 1": Uri.http("behoimi.org", "post/show/653114/2b-blonde_hair-christmas-kaddi_cosplay-nier-nier_a"),
            "e621": Uri.parse("https://e926.net/posts/4869786"),
            "gelbooru 0.2.5": Uri.parse("https://gelbooru.com/index.php?page=post&s=view&id=10237422"),
            "gelbooru 0.2.0": Uri.parse("https://safebooru.org/index.php?page=post&s=view&id=5014759"),
            "furaffinity": Uri.parse("https://www.furaffinity.net/view/57099978/"),
            "deviantArt": Uri.parse("https://www.deviantart.com/pachunka/art/Cope-145564099"),
            "twitter": Uri.parse("https://x.com/ralfyneko/status/1801386308914528722"),
        };
        debugPrint("Starting test");
        for (final website in websites.entries) {
            debugPrint("Testing with ${website.key}");
            final stopwatch = Stopwatch()..start();
            final res = await accurateGetWebsite(website.value);
            stopwatch.stop();
            debugPrint("Found: $res. Took ${stopwatch.elapsed.inMilliseconds}ms\n");
        }
        debugPrint("End of test");
    }

    // image playground
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
                    MultipleImage(images: List.filled(3, const AssetImage("assets/Screenshot_1009.webp"))),
                    const StyleCounter(number: 1234567890, display: "squares",),
                    const StyleCounter(number: 1234567890, display: "baba",),
                    const StyleCounter(number: 1234567890, display: "signs",),
                    const StyleCounter(number: 1234567890, display: "image-goobers"),
                    // FilledButton(
                    //     onPressed: testAccurateIdentification,
                    //     child: const Text("test webcrawing"),
                    // ),
                    // FilledButton(
                    //     child: const Text("test read collection"),
                    //     onPressed: () async {
                    //         final booru = await getCurrentBooru();
                    //         final collection = await booru.getCollection("0");
                    //         debugPrint("${collection?.name} ${collection?.id} ${collection?.pages}");

                    //         final foundCollection = await booru.obtainMatchingCollection("1");
                    //         debugPrint("${foundCollection.map((e) => e.name)}");
                    //     },
                    // ),
                    // FilledButton(
                    //     child: const Text("test write collection"),
                    //     onPressed: () async {
                    //         final booru = await getCurrentBooru();
                            
                    //         // creation
                    //         final extracted = await insertCollection(PresetCollection(
                    //             name: "Created collection",
                    //             pages: ["0", "1"]
                    //         ));
                    //         final idCollection = extracted.id;
                    //         BooruCollection? collection = await booru.getCollection(idCollection);
                    //         debugPrint("${collection?.pages}");

                    //         // override
                    //         await insertCollection(PresetCollection(
                    //             id: idCollection,
                    //             name: "Created collection",
                    //             pages: ["1", "3"]
                    //         ));
                    //         collection = await booru.getCollection(idCollection);
                    //         debugPrint("${collection?.pages}");

                    //         // deletion
                    //         await removeCollection(idCollection);
                    //         collection = await booru.getCollection(idCollection);
                    //         debugPrint("$collection");
                    //     },
                    // ),
                    // FilledButton(
                    //     child: const Text("test write collection"),
                    //     onPressed: () async {
                    //         VirtualPresetCollection.urlToPreset("https://e926.net/pools/42095");
                    //     },
                    // ),
                ],
            )
            // body: AspectRatio(
            //     aspectRatio: 1,
            //     child: FractionallySizedBox(
            //         widthFactor: 0.5,
            //         heightFactor: 0.5,
            //         child: MultipleImage(images: List.filled(3, const AssetImage("assets/Screenshot_1009.webp")))
            //     )
            // ),
        );
    }

    // some sliver test idk
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: CustomScrollView(
//         slivers: [
//           SliverAppBar(
//             pinned: true, // Keeps the AppBar at the top
//             floating: false,
//             expandedHeight: 200.0,
//             flexibleSpace: FlexibleSpaceBar(
//               // Title stays pinned and visible
//               title: Text('Title Stays'),
//               centerTitle: true,
//             ),
//             // The bottom widget, which disappears first
//             bottom: PreferredSize(
//               preferredSize: Size.fromHeight(80), // Height of bottom widget
//               child: Container(
//                 color: Colors.orangeAccent,
//                 height: 80,
//                 child: Center(
//                   child: Text(
//                     'Bottom Widget',
//                     style: TextStyle(color: Colors.white, fontSize: 24),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           SliverList(
//             delegate: SliverChildBuilderDelegate(
//               (context, index) => ListTile(
//                 title: Text('Item #$index'),
//               ),
//               childCount: 30,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
}
