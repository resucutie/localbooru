import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/components/builders.dart';
import 'package:localbooru/components/context_menu.dart';
import 'package:localbooru/components/counter.dart';
import 'package:localbooru/components/drawer.dart';
import 'package:localbooru/utils/constants.dart';
import 'package:localbooru/utils/listeners.dart';
import 'package:localbooru/utils/shared_prefs_widget.dart';

class HomePage extends StatefulWidget {
    const HomePage({super.key});

    @override
    State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
    void _onSearch () {
        context.push("/search?tag=${Uri.encodeComponent(_searchController.text)}");
    }
    final SearchController _searchController = SearchController();


    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                // title: const Text("Home"),
                actions: [
                    IconButton(
                        icon: const Icon(Icons.add),
                        tooltip: "Add image",
                        onPressed: () => context.push("/manage_image")
                    ),
                    PopupMenuButton(
                        itemBuilder: (context) {
                            return [
                                ...booruItems(),
                            ];
                        }
                    )
                ],
            ),
            drawer: MediaQuery.of(context).orientation == Orientation.portrait ? const Drawer(child: DefaultDrawer()) : null,
            body: OrientationBuilder(
                builder: (context, orientation) => LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                        child: Container(
                            padding: const EdgeInsets.all(8.0),
                            constraints: BoxConstraints(minWidth: constraints.maxWidth, minHeight: constraints.maxHeight),
                            child: IntrinsicHeight(
                                child: Column(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                        const SizedBox(height: 64),
                                        const LocalBooruHeader(),
                                        const SizedBox(height: 32),
                                        SearchTag(
                                            onSearch: (_) => _onSearch(),
                                            controller: _searchController,
                                            hint: "Type a tag",
                                        ),
                                        const SizedBox(height: 16),
                                        Wrap(
                                            direction: Axis.horizontal,
                                            spacing: 8,
                                            children: [
                                                OutlinedButton.icon(
                                                    onPressed: () => context.push("/recent"),
                                                    label: const Text("Recent posts"),
                                                    icon: const Icon(Icons.history),
                                                    style: orientation == Orientation.portrait ? OutlinedButton.styleFrom(
                                                        minimumSize: const Size(0, 48)
                                                    ) : null,
                                                ),
                                                orientation == Orientation.landscape ? FilledButton.icon(
                                                    onPressed: _onSearch,
                                                    label: const Text("Search"),
                                                    icon: const Icon(Icons.search)
                                                ) : IconButton.filled(
                                                        onPressed: _onSearch,
                                                    icon: const Icon(Icons.search),
                                                    // color: Theme.of(context).colorScheme.primary,
                                                ),
                                            ],
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                            direction: Axis.horizontal,
                                            spacing: 8,
                                            children: [
                                                OutlinedButton.icon(
                                                    onPressed: () => context.push("/collections"),
                                                    label: const Text("Collections"),
                                                    icon: const Icon(Icons.photo_library),
                                                    style: orientation == Orientation.portrait ? OutlinedButton.styleFrom(
                                                        minimumSize: const Size(0, 48)
                                                    ) : null,
                                                ),
                                            ],
                                        ),
                                        const SizedBox(height: 56),
                                        const ImageDisplay(),
                                        const SizedBox(height: 16),
                                        const Spacer(),
                                        BooruLoader(
                                            builder: (context, booru) => SelectableText(booru.path,
                                                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                                    color: Theme.of(context).hintColor
                                                ),
                                            ),
                                        ),
                                    ]
                                ),
                            )
                        )
                    )
                )
            ),
        );
    }
}

class SearchTag extends StatefulWidget {
    const SearchTag({super.key, this.hint, required this.onSearch, this.controller, this.isFullScreen, this.actions, this.showShadow = false, this.leading = const Icon(Icons.search), this.padding = const EdgeInsets.only(left: 16.0, right: 10.0), this.backgroundColor, this.elevation});

    final String? hint;
    final Function(String value) onSearch;
    final SearchController? controller;
    final bool? isFullScreen;
    final List<Widget>? actions;
    final bool showShadow;
    final Widget? leading;
    final EdgeInsetsGeometry? padding;
    final Color? backgroundColor;
    final double? elevation;

    @override
    State<SearchTag> createState() => _SearchTagState();
}

class _SearchTagState extends State<SearchTag> {
    SearchController _controller = SearchController();

    @override
    void initState() {
        super.initState();

        if(widget.controller != null) _controller = widget.controller!;
    }

    @override
    Widget build(BuildContext context) {
        return SearchAnchor(
            searchController: _controller,
            builder: (context, controller) => SearchBar(
                controller: controller,
                hintText: widget.hint,
                padding: WidgetStatePropertyAll(widget.padding),
                onSubmitted: widget.onSearch,
                onTap: controller.openView,
                onChanged: (_) => controller.openView(),
                leading: widget.leading,
                trailing: [
                    // if(controller.text.isNotEmpty) IconButton(onPressed: _controller.clear, icon: const Icon(Icons.close)),
                    if(widget.actions == null) SearchButton(controller: controller, onSearch: widget.onSearch, icon: const Icon(Icons.arrow_forward),)
                    else ...widget.actions!
                ],
                elevation: WidgetStatePropertyAll(widget.elevation),
                shadowColor: widget.showShadow ? null : const WidgetStatePropertyAll(Colors.transparent),
                backgroundColor: WidgetStatePropertyAll<Color?>(widget.backgroundColor),
            ),
            suggestionsBuilder: (context, controller) async {
                Booru booru = await getCurrentBooru();
                List<String> tags = await booru.getAllTags();
                final currentTags = List<String>.from(controller.text.split(" "));

                final filteredTags = List<String>.from(tags)..addAll(tagsToAddToSearch)..retainWhere((s){
                    return currentTags.last.isEmpty || s.contains(TagText(currentTags.last).text);
                });

                final specialTags = await booru.separateTagsByType(filteredTags);

                return specialTags.entries.map((type) => type.value.map((tag) {
                    final isMetatag = tag.contains(":") && tag.split(":").first.isNotEmpty;
                    final color = !isMetatag ? SpecificTagsColors.getColor(type.key) : null;
                    return ListTile(
                        leading: Icon(!isMetatag ? SpecificTagsIcons.getIcon(type.key) : Icons.lightbulb, color: color,),
                        title: Text(tag,
                            style: TextStyle(
                                color: color,
                                fontWeight: isMetatag ? FontWeight.bold : null
                            ),
                        ),
                        onTap: () {
                            List endResult = List.from(currentTags);
                            endResult.removeLast();
                            endResult.add(tag);
                            setState(() {
                                if(isMetatag) controller.text = endResult.join(" ");
                                else controller.text = "${endResult.join(" ")} ";
                            });
                        },
                    );
                })).expand((i) => i);
            },
            viewTrailing: [
                IconButton(onPressed: _controller.clear, icon: const Icon(Icons.close)),
                SearchButton(controller: _controller, onSearch: widget.onSearch)
            ],
            isFullScreen: widget.isFullScreen,
        );
    }
}
final List<String> tagsToAddToSearch = [
    "rating:none",
    "rating:safe",
    "rating:questionable",
    "rating:explicit",
    "rating:borderline",
    "id:",
    "file:",
    "type:",
    "type:static",
    "type:animated",
    "source:",
    "source:none",
];

class SearchButton extends StatelessWidget {
    const SearchButton({super.key, required this.controller, this.onSearch, this.icon = const Icon(Icons.search)});

    final SearchController controller;
    final Widget icon;
    final Function(String)? onSearch;
    
    @override
    Widget build(context) {
        return IconButton(
            icon: icon,
            onPressed: onSearch != null ? () => onSearch!(controller.text) : null,
        );
    }
}

class LocalBooruHeader extends StatelessWidget {
    const LocalBooruHeader({super.key});
    
    @override
    Widget build(context) {
        return Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            direction: Axis.vertical,
            spacing: 16,
            children: [
                SvgPicture.asset("assets/brand/monochrome-icon.svg",
                    color: Theme.of(context).colorScheme.primary,
                    height: 128,
                ),
                const Text("LocalBooru",
                    style: TextStyle(
                        fontSize: 32,
                    ),
                )
            ],
        );
    }
}

class ImageDisplay extends StatefulWidget {
    const ImageDisplay({super.key});

    @override
    State<ImageDisplay> createState() => _ImageDisplayState();
}

class _ImageDisplayState extends State<ImageDisplay> {
    late Future<int> _futureNumber;

    @override
    void initState() {
        super.initState();
        counterListener.addListener(updateCounter);
        updateCounter();
    }

    @override
    void dispose() {
        counterListener.removeListener(updateCounter);
        super.dispose();
    }

    void updateCounter() async {
        setState(() {
            _futureNumber = (() async => (await getCurrentBooru()).getListLength())();
        });
    }

    @override
    Widget build(context) {
        return SharedPreferencesBuilder(
            builder: (context, prefs) => FutureBuilder(
                future: _futureNumber,
                builder: (context, snapshot) {
                    if(snapshot.hasData) {
                        final String counterType = prefs.getString("counter") ?? settingsDefaults["counter"];
                        // final String counterType = "image-goobers"; // hardcoded
                        return StyleCounter(number: snapshot.data!, display: counterType,);
                    }
                    if(snapshot.hasError) throw snapshot.error!;
                    return const CircularProgressIndicator();
                },
            )
        );
    }
}