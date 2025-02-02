import 'package:flutter/material.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/components/search_tag.dart';
import 'package:localbooru/utils/constants.dart';
import 'package:localbooru/views/navigation/tag_browse.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<List<ImageID>?> openSelectionDialog({required BuildContext context, List<ImageID>? selectedImages, List<ImageID>? excludeImages,}) async {
    final booru = await getCurrentBooru();

    if(!context.mounted) return null;

    final res = await showDialog<List<ImageID>>(
        context: context,
        builder: (context) => SelectDialog(booru: booru, selectedImages: selectedImages, excludeImages: excludeImages,)
    );
    return res;
}

class SelectDialog extends StatefulWidget {
    const SelectDialog({super.key, required this.booru, this.selectedImages, this.excludeImages});

    final Booru booru;
    final List<ImageID>? selectedImages;
    final List<ImageID>? excludeImages;

    @override
    State<SelectDialog> createState() => _SelectDialogState();
}
class _SelectDialogState extends State<SelectDialog> {
    final SearchController controller = SearchController();

    List<ImageID> imageIDs = [];

    String tags = "";

    @override
    void initState() {
        super.initState();
        imageIDs = widget.selectedImages ?? [];
    }

    void onSearch() {
        setState(() {
            tags = controller.text;
        });
        debugPrint(tags);
    }

    @override
    Widget build(context) {
        return OrientationBuilder(
            builder: (context, orientation) {
                return AlertDialog(
                    // backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    elevation: 0,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8).add(const EdgeInsets.only(bottom: 24)),
                    titlePadding: const EdgeInsets.all(16).subtract(const EdgeInsets.only(bottom: 8)),
                    clipBehavior: Clip.antiAlias,
                    titleTextStyle: const TextStyle(
                        fontSize: 18
                    ),
                    title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            // Padding(
                            //     padding: const EdgeInsets.all(16.0),
                            //     child: Text("Selected: ${imageIDs.length}"),
                            // ),
                            Container(
                                constraints: const BoxConstraints(maxHeight: 44),
                                child: SearchTag(
                                    controller: controller,
                                    onSearch: (value) => onSearch(),
                                    hint: imageIDs.isNotEmpty ? "Selected: ${imageIDs.length}" : "Select elements",
                                    leading: const Padding(
                                        padding: EdgeInsets.only(right: 12.0, left: 8),
                                        child: Icon(Icons.search),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                            ),
                        ],
                    ),
                    actions: [
                        TextButton(
                            onPressed: Navigator.of(context).pop,
                            child: const Text("Cancel"),
                        ),
                        TextButton(
                            child: const Text("Select"),
                            onPressed: () => Navigator.of(context).pop(imageIDs),
                        )
                    ],
                    content: SizedBox(
                        width: MediaQuery.of(context).size.width * (orientation == Orientation.landscape ? 0.6 : 1),
                        child: GalleryViewer(
                            key: ValueKey(tags),
                            searcher: (index) async {
                                SharedPreferences prefs = await SharedPreferences.getInstance();
                                final Booru booru = await getCurrentBooru();
                                int indexSize = prefs.getInt("page_size") ?? settingsDefaults["page_size"];

                                final finalTags = [tags, ...(widget.excludeImages ?? []).map((e) => "-id:$e")].join(" ");

                                int indexLength = await booru.getIndexNumberLength(finalTags, size: indexSize);
                                List<BooruImage> images = await booru.searchByTags(finalTags, index: index, size: indexSize);
                                return SearchableInformation(images: images, indexLength: indexLength);
                            },
                            selectionMode: true,
                            selectedImages: imageIDs,
                            onSelect: (images) => setState(() => imageIDs = images),
                        ),
                    ),
                );
            }
        );
    }
}