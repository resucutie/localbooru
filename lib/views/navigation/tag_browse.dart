import 'dart:async';
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
import 'package:localbooru/api/preset/index.dart';
import 'package:localbooru/views/navigation/home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliver_tools/sliver_tools.dart';

class GalleryViewer extends StatefulWidget {
    const GalleryViewer({super.key, required this.searcher, this.headerDisplay, this.index = 0, this.selectionMode = false, this.onSelect, this.onNextPage, this.selectedImages, this.displayBackButton = true, this.forceOrientation, this.onAddPressed, this.additionalMenuOptions});

    final int index;
    final FutureOr<SearchableInformation> Function(int index) searcher;
    final Widget Function(BuildContext context, Orientation orientation)? headerDisplay;
    final bool selectionMode;
    final bool displayBackButton;
    final Orientation? forceOrientation;
    final void Function(List<ImageID>)? onSelect;
    final void Function(int newIndex)? onNextPage;
    final void Function()? onAddPressed;
    final List<ImageID>? selectedImages;
    final List<PopupMenuEntry<dynamic>>? additionalMenuOptions;

    @override
    State<GalleryViewer> createState() => _GalleryViewerState();
}

class _GalleryViewerState extends State<GalleryViewer> {
    late Future<Map> _resultObtainFuture;

    final scrollToTop = GlobalKey();
    
    late int _currentIndex;

    List<ImageID> _selectedImages = [];

    @override
    void initState() {
        super.initState();
        _currentIndex = widget.index;
        _selectedImages = widget.selectedImages ?? [];
        updateImages();

        booruUpdateListener.addListener(updateImages);
    }

    @override
    void dispose() {
        booruUpdateListener.removeListener(updateImages);
        super.dispose();
    }

    void updateImages() {
        setState(() {
            _resultObtainFuture = _obtainResults();
        });
    }

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
        if(widget.additionalMenuOptions != null) ...[
            const PopupMenuDivider(),
            ...widget.additionalMenuOptions!
        ],
        const PopupMenuDivider(),
        ...imageManagementItems(image, context: context),
    ];

    List<PopupMenuEntry> multipleContextMenuItems(List<BooruImage> images) => [
        if(widget.additionalMenuOptions != null) ...[
            ...widget.additionalMenuOptions!,
            const PopupMenuDivider(),
        ],
        ...multipleImageManagementItems(images, context: context),
    ];

    void toggleImageSelection(ImageID imageID) {
        setState(() {
            if(_selectedImages.contains(imageID)) _selectedImages.remove(imageID);
            else _selectedImages.add(imageID);
        });
        if(widget.onSelect != null) widget.onSelect!(_selectedImages);
    }

    Future<Map> _obtainResults() async {
        final search = await widget.searcher(_currentIndex);

        return {
            "images": search.images,
            "indexLength": search.indexLength,
            "sharedPrefs": await SharedPreferences.getInstance()
        };
    }

    bool isInSelection() => widget.selectionMode || _selectedImages.isNotEmpty;

    @override
    Widget build(BuildContext context) {
        final actions = [
            IconButton(
                icon: const Icon(Icons.add),
                tooltip: "Add image",
                onPressed: widget.onAddPressed,
            ),
            PopupMenuButton(
                itemBuilder: (context) {
                    return [
                        ...booruItems(),
                        if(widget.additionalMenuOptions != null) ...[
                            const PopupMenuDivider(),
                            ...widget.additionalMenuOptions!
                        ]
                    ];
                }
            )
        ];
        return FutureBuilder<Map>(
            future: _resultObtainFuture,
            builder: (context, snapshot) {
                if(snapshot.hasData) {
                    int pages = snapshot.data!["indexLength"];
                    SharedPreferences prefs = snapshot.data!["sharedPrefs"];
                
                    return OrientationBuilder(
                        builder: (context, containerOrientation) {
                            final Orientation orientation = widget.forceOrientation ?? containerOrientation;
                            return Scaffold(
                                body: CustomScrollView(
                                    slivers: [
                                        if(!widget.selectionMode) SliverAnimatedSwitcher(
                                            duration: kThemeAnimationDuration,
                                            child: !isInSelection()
                                                ? SliverAppBar(
                                                    key: const ValueKey("normal"),
                                                    floating: true,
                                                    snap: true,
                                                    pinned: isDesktop(),
                                                    forceMaterialTransparency: orientation == Orientation.landscape,
                                                    titleSpacing: 0,
                                                    automaticallyImplyLeading: widget.displayBackButton,
                                                    actions: orientation != Orientation.landscape ? actions : [Padding(
                                                        padding: const EdgeInsets.only(right: 8),
                                                        child: Wrap(
                                                            direction: Axis.horizontal,
                                                            spacing: 8,
                                                            children: actions.map((e) => CircleAvatar(
                                                                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                                                                child: e,
                                                            )).toList(),
                                                        ),
                                                    )],
                                                    title: widget.headerDisplay != null ? widget.headerDisplay!(context, orientation) : null,
                                                )
                                                : SliverAppBar(
                                                    key: const ValueKey("elements selected"),
                                                    floating: true,
                                                    snap: true,
                                                    pinned: true,
                                                    // forceElevated: true,
                                                    automaticallyImplyLeading: false,
                                                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                                    leading: CloseButton(onPressed: () => setState(() => _selectedImages = []),),
                                                    actions: [
                                                        if(_selectedImages.length == 1) IconButton(
                                                            icon: const Icon(Icons.edit),
                                                            onPressed: () async {
                                                                context.push("/manage_image", extra: VirtualPresetCollection(pages: [await PresetImage.fromExistingImage(snapshot.data!["images"].firstWhere((element) => element.id == _selectedImages[0]))]));
                                                                setState(() => _selectedImages = []);
                                                            },
                                                        ),
                                                        PopupMenuButton(itemBuilder: (context) {
                                                            if(_selectedImages.length == 1) return singleContextMenuItems(snapshot.data!["images"].firstWhere((element) => element.id == _selectedImages[0]));
                                                            else if(_selectedImages.length > 1) return multipleContextMenuItems(snapshot.data!["images"].where((element) => _selectedImages.contains(element.id)).toList());
                                                            return [];
                                                        }, onSelected: (value) => setState(() => _selectedImages = []))
                                                    ],
                                                    title: Text("${_selectedImages.length} Selected")
                                                ),
                                        ),
                                        SliverToBoxAdapter(child: SizedBox(key:scrollToTop, height: 0.0)),
                                        if (pages == 0) const SliverFillRemaining(child: Center(child: Text("nothing to see here!")))
                                        else ...[
                                            SliverRepoGrid(
                                                key: ValueKey("$_currentIndex"),
                                                images: snapshot.data!["images"],
                                                onPressed: (image) {
                                                    if(isInSelection()) toggleImageSelection(image.id);
                                                    else context.push("/view/${image.id}");
                                                },
                                                autoadjustColumns: prefs.getInt("grid_size") ?? settingsDefaults["grid_size"],
                                                dragOutside: !isMobile(),
                                                onContextMenu: openContextMenu,
                                                onLongPress: (image) => toggleImageSelection(image.id),
                                                selectedElements: _selectedImages,
                                                isSelection: isInSelection(),
                                            ),
                                            SliverToBoxAdapter(child: PageDisplay(
                                                currentPage: _currentIndex,
                                                pages: pages,
                                                onSelect: (selectedPage) {
                                                    if(widget.onNextPage != null) {
                                                        widget.onNextPage!(selectedPage);
                                                    } else {
                                                        _currentIndex = selectedPage;
                                                        updateImages();
                                                        Scrollable.ensureVisible(scrollToTop.currentContext!);
                                                    }
                                                },
                                            )),
                                        ],
                                    ]
                                ),
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

class SearchBarOnGridList extends StatefulWidget {
    const SearchBarOnGridList({super.key, required this.onSearch, required this.desktopDisplay, this.initialText = ""});

    final void Function(String text) onSearch;
    final bool desktopDisplay;
    final String initialText;

    @override
    State<SearchBarOnGridList> createState() => _SearchBarOnGridListState();

}

class _SearchBarOnGridListState extends State<SearchBarOnGridList> {
    final SearchController _searchController = SearchController();

    @override
    void initState() {
        _searchController.text = widget.initialText;
        super.initState();
    }

    @override
    Widget build(BuildContext context) {
        return Container(
            padding: widget.desktopDisplay ? const EdgeInsets.all(16.0) : null,
            constraints: widget.desktopDisplay ? const BoxConstraints(maxWidth: 560, maxHeight: 74) : null,
            child: SearchTag(
                onSearch: (text) => widget.onSearch(text),
                controller: _searchController,
                actions: !widget.desktopDisplay ? [] : [IconButton(onPressed: () => widget.onSearch(_searchController.text), icon: const Icon(Icons.search))],
                leading: const Padding(
                    padding: EdgeInsets.only(right: 12.0),
                    child: BackButton(),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8).add(const EdgeInsets.only(bottom: 2)),
                backgroundColor: !widget.desktopDisplay ? Colors.transparent : null,
                elevation: !widget.desktopDisplay ? 0 : null,
                hint: "Search",
            ),
        );
    }
}

class SearchableInformation {
    SearchableInformation({required this.images, required this.indexLength});
    
    List<BooruImage> images;
    int indexLength;
}