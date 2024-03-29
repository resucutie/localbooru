import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/components/image_display.dart';
import 'package:localbooru/utils/constants.dart';
import 'package:localbooru/views/navigation/home.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final SearchController _searchController = SearchController();
    void _onSearch () => context.push("/search?tag=${Uri.encodeComponent(_searchController.text)}");

    final scrollToTop = GlobalKey();
    
    late int _currentIndex;

    @override
    void initState() {
        super.initState();
        _currentIndex = widget.index;
        _searchController.text = widget.tags;
    }

    Future<Map> _obtainResults() async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        int indexSize = prefs.getInt("page_size") ?? settingsDefaults["page_size"];

        int indexLength = await widget.booru.getIndexNumberLength(widget.tags, size: indexSize);
        List<BooruImage> images = await widget.booru.searchByTags(widget.tags, index: _currentIndex, size: indexSize);
        return {
            "images": images,
            "indexLength": indexLength,
            "sharedPrefs": prefs
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
                                SharedPreferences prefs = snapshot.data!["sharedPrefs"];

                                if (pages == 0) return const Center(child: Text("nothing to see here!"));

                                return CustomScrollView(
                                    slivers: [
                                        SliverPersistentHeader(
                                            delegate: SearchBarHeaderDelegate(onSearch: (_) => _onSearch(), searchController: _searchController),
                                            pinned: true,
                                        ),
                                        SliverToBoxAdapter(child: SizedBox(key:scrollToTop, height: 0.0)),
                                        SilverRepoGrid(
                                            images: snapshot.data!["images"],
                                            onPressed: (image) => context.push("/view/${image.id}"),
                                            autoadjustColumns: prefs.getInt("grid_size") ?? settingsDefaults["grid_size"],
                                        ),
                                        SliverToBoxAdapter(child: PageDisplay(
                                            currentPage: _currentIndex,
                                            pages: pages,
                                            onSelect: (selectedPage) {
                                                if(widget.routeNavigation) {
                                                    context.push("/search?tag=${widget.tags}&index=$selectedPage");
                                                } else {
                                                    setState(() => _currentIndex = selectedPage);
                                                    Scrollable.ensureVisible(scrollToTop.currentContext!);
                                                }
                                            },
                                        )),
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
    final SearchController searchController;

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

class PageDisplay extends StatefulWidget {
    const PageDisplay({super.key, this.height = 48.0, required this.currentPage, required this.pages, this.onSelect});
    final double height;
    final int pages;
    final int currentPage;
    final Function(int selectedPage)? onSelect;

    @override
    State<PageDisplay> createState() => _PageDisplayState();
}

class _PageDisplayState extends State<PageDisplay> {
    final controller = ScrollController();
    final jumpToKey = GlobalKey();

    @override
    void initState() {
        super.initState();
        SchedulerBinding.instance.addPostFrameCallback((_) {
            final jumpRenderBox = jumpToKey.currentContext!.findRenderObject() as RenderBox;
            double jumpTo = jumpRenderBox.localToGlobal(const Offset(-128, 0)).dx;
            if(controller.position.maxScrollExtent < jumpTo) jumpTo = controller.position.maxScrollExtent;
            if(jumpTo < 0) jumpTo = 0;
            controller.jumpTo(jumpTo < 0 ? 0 : jumpTo);
        });
    }

    @override
    Widget build(context) {
        return SizedBox(
            height: widget.height,
            child: ScrollConfiguration(
                behavior: const MaterialScrollBehavior().copyWith(
                    dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch, PointerDeviceKind.trackpad, PointerDeviceKind.stylus},
                ),
                child: Listener(
                    onPointerSignal: (event) {
                        if(event is! PointerScrollEvent) return;

                        controller.animateTo(controller.offset + (event.scrollDelta.dy * 4), duration: const Duration(milliseconds: 100), curve: Curves.easeOut);
                    },
                    child: Center(
                        child: SingleChildScrollView(
                            controller: controller,
                            scrollDirection: Axis.horizontal,
                            child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(widget.pages, (index) {
                                    final bool isCurrentPage = widget.currentPage == index;
                                    Widget icon = Text((index + 1).toString());
                                    final ButtonStyle buttonStyle = TextButton.styleFrom(
                                        minimumSize: Size.zero,
                                        padding: const EdgeInsets.all(12.0),
                                    );
                        
                                    void onPressed() {
                                        if(isCurrentPage) return;
                                        if(widget.onSelect != null) widget.onSelect!(index);
                                    }
                        
                                    return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: isCurrentPage
                                            ? FilledButton(key: jumpToKey, onPressed: onPressed, style: buttonStyle, child: icon)
                                            : OutlinedButton(onPressed: onPressed, style: buttonStyle, child: icon)
                                    );
                                }),
                            )
                        ),
                    ),
                )
                    // child: ListView.separated(
                    //     itemCount: widget.pages,
                    //     scrollDirection: Axis.horizontal,
                    //     padding: const EdgeInsets.all(8.0),
                    //     shrinkWrap: true,
                    //     separatorBuilder: (context, index) => const SizedBox(width: 8),
                    //     itemBuilder: (context, index) {
                    //     }
                    // ),
            ),
        );
    }
}