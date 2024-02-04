import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/components/image-display.dart';

class SearchTagView extends StatefulWidget {
    const SearchTagView({super.key});

    @override
    State<SearchTagView> createState() => _SearchTagViewState();
}



class _SearchTagViewState extends State<SearchTagView> {
    void _onSearch () => context.push("/search?tag=${_searchController.text}");
    final TextEditingController _searchController = TextEditingController();


    @override
    Widget build(BuildContext context) {
        return Center(
            child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                        SearchTag(
                            onSearch: (_) => _onSearch(),
                            controller: _searchController,
                        ),
                        const SizedBox(height: 16.0),
                        Wrap(
                            direction: Axis.horizontal,
                            spacing: 8.0,
                            children: [
                                OutlinedButton.icon(
                                    onPressed: () => context.push("/recent"),
                                    label: const Text("Recent posts"),
                                    icon: const Icon(Icons.history)
                                ),
                                // FilledButton.icon(
                                //     onPressed: () => _onSearch(),
                                //     label: const Text("Search"),
                                //     icon: const Icon(Icons.search)
                                // )
                            ],
                        )
                    ],
                ),
            )
        );
    }
}

class SearchTag extends StatefulWidget {
    SearchTag({super.key, this.defaultText = "", required this.onSearch, this.controller});

    String defaultText = "";
    TextEditingController? controller = TextEditingController();
    Function(String value) onSearch;

    @override
    State<SearchTag> createState() => _SearchTagState();
}

class _SearchTagState extends State<SearchTag> {
    // SearchTag({super.key, this.defaultText = "", required this.onSearch, this.controller});

    // String defaultText = "";
    // TextEditingController? controller = TextEditingController();
    // Function(String value) onSearch;

    bool _isEmpty = true;

    @override
    void initState() {
        super.initState();

        _isEmpty = widget.controller!.text.isEmpty;
    }

    @override
    Widget build(BuildContext context) {
        return SearchBar(
            controller: widget.controller,
            hintText: "Type a tag",
            hintStyle: MaterialStateProperty.all(TextStyle(color: Colors.grey)),
            backgroundColor: MaterialStateProperty.all(Theme.of(context).colorScheme.surfaceVariant),
            shadowColor: MaterialStateProperty.all(Colors.transparent),
            textStyle: MaterialStateProperty.all(
                TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)
            ),
            onSubmitted: widget.onSearch,
            onChanged: (text) => setState(() {
                _isEmpty = text.isEmpty;
            }),
            trailing: [
                IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _isEmpty ? null : () => widget.onSearch(widget.controller!.text),
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    // disabledColor: Colors.grey,
                )
            ]
        );
    }
}

class GalleryViewer extends StatefulWidget {
    GalleryViewer({super.key, required this.booru, this.tags = "", this.index = 0, this.routeNavigation = false});

    final Booru booru;
    String tags = "";
    int index = 0;
    bool routeNavigation = false;

    @override
    State<GalleryViewer> createState() => _GalleryViewerState();
}

class _GalleryViewerState extends State<GalleryViewer> {
    final TextEditingController _searchController = TextEditingController();
    void _onSearch () => context.push("/search?tag=${_searchController.text}");

    final scrollToTop = GlobalKey();
    
    // late int _currentIndex = widget.index;

    // @override
    // void initState() {
    //     super.initState();

    //     _searchController.text = widget.tags;
    // }

    Future<Map> _obtainResults() async {
        debugPrint("tags: ${widget.tags}");
        _searchController.text = widget.tags;
        
        int indexLength = await widget.booru.getIndexNumberLength(widget.tags);
        List<BooruImage> images = await widget.booru.searchByTags(widget.tags, index: widget.index);
        return {
            "images": images,
            "indexLength": indexLength,
        };
    }

    @override
    Widget build(BuildContext context) {

        return Column(
            children: [
                // Padding(
                //     padding: const EdgeInsets.all(8.0),
                //     child: SearchTag(
                //             onSearch: (_) => _onSearch(),
                //             controller: _searchController,
                //     ),
                // ),
                Expanded(
                    child: FutureBuilder<Map>(
                        future: _obtainResults(),
                        builder: (context, snapshot) {
                            if(snapshot.hasData) {
                                debugPrint("meow ${widget.index}");
                                int pages = snapshot.data!["indexLength"];
                                // List<Widget> numberPage = [];

                                // for (int i=0; i<pages; i++) {
                                //     numberPage.add(GestureDetector(
                                //         onTap: () {
                                //             if(_currentIndex != i) setState(() => _currentIndex = i);
                                //         },
                                //         child: Text((i + 1).toString())
                                //     ));
                                // }

                                if (pages == 0) return const Center(child: Text("nothing to see here!"));

                                return CustomScrollView(
                                    slivers: [
                                        SliverPersistentHeader(
                                            delegate: SearchBarHeaderDelegate(onSearch: (_) => _onSearch(), searchController: _searchController),
                                            pinned: true,
                                        ),
                                        SliverToBoxAdapter(child: SizedBox(key:scrollToTop, height: 0.0)),
                                        RepoGrid(images: snapshot.data!["images"]),
                                        SliverToBoxAdapter(
                                            child: SizedBox(
                                                height: 48.0,
                                                child: ListView.builder(
                                                    physics: const ClampingScrollPhysics(),
                                                    itemCount: pages,
                                                    scrollDirection: Axis.horizontal,
                                                    padding: const EdgeInsets.all(8.0),
                                                    itemBuilder: (context, index) {
                                                        final bool isCurrentPage = widget.index == index;
                                                        Widget icon = Text((index + 1).toString());
                                                        final ButtonStyle buttonStyle = TextButton.styleFrom(
                                                            minimumSize: Size.zero,
                                                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                                        );


                                                        void onPressed() {
                                                            if(isCurrentPage) return;
                                                            if(widget.routeNavigation) {
                                                                context.push("/search?tag=${widget.tags}&index=$index");
                                                            } else {
                                                                setState(() => widget.index = index);
                                                                Scrollable.ensureVisible(scrollToTop.currentContext!);
                                                            }
                                                        }
                                                        
                                                        return isCurrentPage
                                                                ? FilledButton(onPressed: onPressed, style: buttonStyle, child: icon)
                                                                : OutlinedButton(onPressed: onPressed, style: buttonStyle, child: icon);
                                                        // if (isCurrentPage) return IconButton.filled(icon: icon, onPressed: onPressed);
                                                        // return IconButton.outlined(icon: icon,onPressed: onPressed);
                                                    }
                                                ),
                                            ),
                                        ),
                                    ]
                                );
                            } else if(snapshot.hasError) {
                                throw snapshot.error!;
                            }
                            return const Center(child: CircularProgressIndicator());
                        }
                    )
                )
            ],
        );
    }
}


class SearchBarHeaderDelegate extends SliverPersistentHeaderDelegate {
    final double height;
    Function(String value) onSearch;
    final TextEditingController searchController;


    SearchBarHeaderDelegate({required this.onSearch, required this.searchController, this.height = 56.0});

    @override
    Widget build(context, double shrinkOffset, bool overlapsContent) {
        return Padding(
            padding: const EdgeInsets.all(8.0),
            child: SearchTag(
                    onSearch: onSearch,
                    controller: searchController,
            ),
        );
    }

    @override
    double get maxExtent => height;

    @override
    double get minExtent => height;

    @override
    bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) => false;
}