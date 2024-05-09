import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/components/context_menu.dart';
import 'package:localbooru/components/image_grid_display.dart';
import 'package:localbooru/utils/constants.dart';
import 'package:localbooru/utils/listeners.dart';
import 'package:localbooru/utils/platform_tools.dart';
import 'package:localbooru/views/navigation/home.dart';
import 'package:localbooru/views/navigation/index.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliver_tools/sliver_tools.dart';

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
    late Future<Map> _resultObtainFuture;

    final SearchController _searchController = SearchController();
    final ScrollController _whyDoWeHaveToAddThis = ScrollController();

    final scrollToTop = GlobalKey();
    
    late int _currentIndex;

    List<ImageID> _selectedImages = [];

    @override
    void initState() {
        super.initState();
        _currentIndex = widget.index;
        _searchController.text = widget.tags;
        updateImages();

        booruUpdateListener.addListener(updateImages);
    }

    @override
    void dispose() {
        booruUpdateListener.removeListener(updateImages);
        super.dispose();
    }

    void updateImages() {
        debugPrint("helo");
        setState(() {
            _resultObtainFuture = _obtainResults();
        });
    }

    void _onSearch () => context.push("/search?tag=${Uri.encodeComponent(_searchController.text)}");

    void openContextMenu(Offset offset, BooruImage image) {
        final RenderObject? overlay = Overlay.of(context).context.findRenderObject();
        showMenu(
            context: context,
            position: RelativeRect.fromRect(
                Rect.fromLTWH(offset.dx, offset.dy, 10, 10),
                Rect.fromLTWH(0, 0, overlay!.paintBounds.size.width, overlay.paintBounds.size.height),
            ),
            items: singleContextMenuItems(image)
        );
    }

    List<PopupMenuEntry> singleContextMenuItems(BooruImage image) => [
        PopupMenuItem(
            child: ListTile(
                title: const Text("Select"),
                trailing: Icon(_selectedImages.contains(image.id) ? Icons.check_box : Icons.check_box_outline_blank),
            ),
            onTap: () => toggleImageSelection(image.id),
        ),
        const PopupMenuDivider(),
        ...imageShareItems(image),
        const PopupMenuDivider(),
        ...imageManagementItems(image, context: context),
    ];

    void toggleImageSelection(ImageID imageID) {
        setState(() {
            if(_selectedImages.contains(imageID)) _selectedImages.remove(imageID);
            else _selectedImages.add(imageID);
        });
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
        final actions = [
            IconButton(
                icon: const Icon(Icons.add),
                tooltip: "Add image",
                onPressed: () => context.push("/manage_image"),
            ),
            const BrowseScreenPopupMenuButton()
        ];
        return FutureBuilder<Map>(
            future: _resultObtainFuture,
            builder: (context, snapshot) {
                if(snapshot.hasData) {
                    int pages = snapshot.data!["indexLength"];
                    SharedPreferences prefs = snapshot.data!["sharedPrefs"];
        
                    if (pages == 0) return const Center(child: Text("nothing to see here!"));
        
                    return OrientationBuilder(
                        builder: (context, orientation) {
                            return Scaffold(
                                body: Scrollbar(
                                    thumbVisibility: isDesktop(),
                                    trackVisibility: isDesktop(),
                                    controller: _whyDoWeHaveToAddThis,
                                    child: Padding(
                                        padding: EdgeInsets.only(right: isDesktop() ? 14.0 : 0),
                                        child: CustomScrollView(
                                            controller: _whyDoWeHaveToAddThis,
                                            scrollBehavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                                            slivers: [
                                                SliverAnimatedSwitcher(
                                                    duration: kThemeAnimationDuration,
                                                    child: _selectedImages.isEmpty
                                                        ? SliverAppBar(
                                                                key: const ValueKey("normal"),
                                                                floating: true,
                                                                snap: true,
                                                                pinned: isDesktop(),
                                                                forceMaterialTransparency: orientation == Orientation.landscape,
                                                                titleSpacing: 0,
                                                                automaticallyImplyLeading: false,
                                                                actions: orientation != Orientation.landscape ? actions : [Padding(
                                                                    padding: const EdgeInsets.only(right: 8),
                                                                    child: Wrap(
                                                                        direction: Axis.horizontal,
                                                                        spacing: 8,
                                                                        children: actions.map((e) => CircleAvatar(backgroundColor: Theme.of(context).colorScheme.surfaceVariant, child: e,)).toList(),
                                                                    ),
                                                                )],
                                                                title: Container(
                                                                    padding: orientation == Orientation.landscape ? const EdgeInsets.all(16.0) : null,
                                                                    constraints: orientation == Orientation.landscape ? const BoxConstraints(maxWidth: 560, maxHeight: 74) : null,
                                                                    child: SearchTag(
                                                                        onSearch: (_) => _onSearch(),
                                                                        controller: _searchController,
                                                                        actions: orientation == Orientation.portrait ? [] : [IconButton(onPressed: _onSearch, icon: const Icon(Icons.search))],
                                                                        leading: const Padding(
                                                                            padding: EdgeInsets.only(right: 12.0),
                                                                            child: BackButton(),
                                                                        ),
                                                                        padding: const EdgeInsets.symmetric(horizontal: 8).add(const EdgeInsets.only(bottom: 2)),
                                                                        backgroundColor: orientation == Orientation.portrait ? Colors.transparent : null,
                                                                        elevation: orientation == Orientation.portrait ? 0 : null,
                                                                    ),
                                                                ),
                                                            )
                                                        : SliverAppBar(
                                                                key: const ValueKey("elements selected"),
                                                                floating: true,
                                                                snap: true,
                                                                pinned: true,
                                                                forceElevated: true,
                                                                leading: CloseButton(onPressed: () => setState(() => _selectedImages = []),),
                                                                actions: [
                                                                    if(_selectedImages.length == 1) IconButton(
                                                                        icon: const Icon(Icons.edit),
                                                                        onPressed: () {
                                                                            context.push("/manage_image/internal/${_selectedImages[0]}");
                                                                            setState(() => _selectedImages = []);
                                                                        },
                                                                    ),
                                                                    PopupMenuButton(itemBuilder: (context) {
                                                                        if(_selectedImages.length == 1) return singleContextMenuItems(snapshot.data!["images"].firstWhere((element) => element.id == _selectedImages[0]));
                                                                        else if(_selectedImages.length > 1) return multipleImageManagementItems(snapshot.data!["images"].where((element) => _selectedImages.contains(element.id)).toList(), context: context);
                                                                        return [];
                                                                    }, onSelected: (value) => setState(() => _selectedImages = []))
                                                                ],
                                                                title: Text("${_selectedImages.length} Selected")
                                                            ),
                                                ),
                                                SliverToBoxAdapter(child: SizedBox(key:scrollToTop, height: 0.0)),
                                                SliverRepoGrid(
                                                    images: snapshot.data!["images"],
                                                    onPressed: (image) {
                                                        if(_selectedImages.isNotEmpty) toggleImageSelection(image.id);
                                                        else context.push("/view/${image.id}");
                                                    },
                                                    autoadjustColumns: prefs.getInt("grid_size") ?? settingsDefaults["grid_size"],
                                                    dragOutside: _selectedImages.isEmpty,
                                                    onContextMenu: openContextMenu,
                                                    onLongPress: (image) => toggleImageSelection(image.id),
                                                    selectedElements: _selectedImages,
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
                                        ),
                                    ),
                                )
                            );
                        }
                    );
                } else if(snapshot.hasError) throw snapshot.error!;
                return const Center(child: CircularProgressIndicator());
            }
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
                    isFullScreen: false,
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

    final ButtonStyle indicatorStyle = TextButton.styleFrom(
        minimumSize: const Size.square(38),
        maximumSize: const Size.square(38),
        padding: const EdgeInsets.all(0),
    );

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
                                    Widget icon = Text((index + 1).toString(), textAlign: TextAlign.center,);
                        
                                    void onPressed() {
                                        if(isCurrentPage) return;
                                        if(widget.onSelect != null) widget.onSelect!(index);
                                    }
                        
                                    return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: isCurrentPage
                                            ? FilledButton(key: jumpToKey, onPressed: onPressed, style: indicatorStyle, child: icon)
                                            : OutlinedButton(onPressed: onPressed, style: indicatorStyle, child: icon)
                                    );
                                }),
                            )
                        ),
                    ),
                )
            ),
        );
    }
}