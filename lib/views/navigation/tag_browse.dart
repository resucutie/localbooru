import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/components/image_display.dart';

class SearchTag extends StatefulWidget {
    const SearchTag({super.key, this.defaultText = "", required this.onSearch, this.controller, this.hasShadows = false});

    final String defaultText;
    final Function(String value) onSearch;
    final TextEditingController? controller;
    final bool hasShadows;

    @override
    State<SearchTag> createState() => _SearchTagState();
}

class _SearchTagState extends State<SearchTag> {
    TextEditingController _controller = TextEditingController();

    @override
    void initState() {
        super.initState();

        if(widget.controller != null) _controller = widget.controller!;
    }

    @override
    Widget build(BuildContext context) {
        return SearchBar(
            controller: _controller,
            hintText: "Type a tag",
            hintStyle: MaterialStateProperty.all(const TextStyle(color: Colors.grey)),
            backgroundColor: MaterialStateProperty.all(Theme.of(context).colorScheme.surfaceVariant),
            shadowColor: !widget.hasShadows ? MaterialStateProperty.all(Colors.transparent) : null,
            textStyle: MaterialStateProperty.all(
                TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)
            ),
            onSubmitted: widget.onSearch,
            trailing: [
                IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _controller.text.isEmpty ? null : () => widget.onSearch(_controller.text),
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    // disabledColor: Colors.grey,
                )
            ]
        );
    }
}

class GalleryViewer extends StatefulWidget {
    const GalleryViewer({super.key, required this.booru, this.tags = "", this.index = 0, this.routeNavigation = false});

    final Booru booru;
    final String tags;
    final int index;
    final bool routeNavigation;

    @override
    State<GalleryViewer> createState() => _GalleryViewerState();
}

class _GalleryViewerState extends State<GalleryViewer> {
    final TextEditingController _searchController = TextEditingController();
    void _onSearch () => context.push("/search?tag=${_searchController.text}");

    final scrollToTop = GlobalKey();
    
    late int _currentIndex;

    @override
    void initState() {
        super.initState();
        _currentIndex = widget.index;
        _searchController.text = widget.tags;
    }

    // @override
    // void initState() {
    //     super.initState();

    //     _searchController.text = widget.tags;
    // }

    Future<Map> _obtainResults() async {
        int indexLength = await widget.booru.getIndexNumberLength(widget.tags);
        List<BooruImage> images = await widget.booru.searchByTags(widget.tags, index: _currentIndex);
        return {
            "images": images,
            "indexLength": indexLength,
        };
    }

    @override
    Widget build(BuildContext context) {

        return Column(
            children: [
                Expanded(
                    child: FutureBuilder<Map>(
                        future: _obtainResults(),
                        builder: (context, snapshot) {
                            if(snapshot.hasData) {
                                int pages = snapshot.data!["indexLength"];

                                if (pages == 0) return const Center(child: Text("nothing to see here!"));

                                return CustomScrollView(
                                    slivers: [
                                        SliverPersistentHeader(
                                            delegate: SearchBarHeaderDelegate(onSearch: (_) => _onSearch(), searchController: _searchController),
                                            pinned: true,
                                        ),
                                        SliverToBoxAdapter(child: SizedBox(key:scrollToTop, height: 0.0)),
                                        SilverRepoGrid(images: snapshot.data!["images"]),
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
                                                                setState(() => _currentIndex = index);
                                                                Scrollable.ensureVisible(scrollToTop.currentContext!);
                                                            }
                                                        }
                                                        
                                                        return isCurrentPage
                                                                ? FilledButton(onPressed: onPressed, style: buttonStyle, child: icon)
                                                                : OutlinedButton(onPressed: onPressed, style: buttonStyle, child: icon);
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
        return Center(
            child: Container(
                padding: const EdgeInsets.all(8.0),
                constraints: const BoxConstraints(maxWidth: 1080),
                child: SearchTag(
                    onSearch: onSearch,
                    controller: searchController,
                    hasShadows: true,
                ),
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