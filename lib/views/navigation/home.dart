import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/views/navigation/tag_browse.dart';

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
                                )
                            ],
                        )
                    ],
                ),
            )
        );
    }
}

class SearchTag extends StatefulWidget {
    const SearchTag({super.key, this.defaultText = "", required this.onSearch, this.controller, this.hasShadows = false});

    final String defaultText;
    final Function(String value) onSearch;
    final SearchController? controller;
    final bool hasShadows;

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
                hintText: "Type a tag",
                padding: const MaterialStatePropertyAll<EdgeInsets>(
                    EdgeInsets.only(left: 16.0, right: 10.0)
                ),
                onSubmitted: widget.onSearch,
                onTap: controller.openView,
                onChanged: (_) => controller.openView(),
                leading: const Icon(Icons.search),
                trailing: [
                    _SearchButton(controller: controller, onSearch: widget.onSearch, icon: const Icon(Icons.arrow_forward),)
                ]
            ),
            suggestionsBuilder: (context, controller) async {
                Booru booru = await getCurrentBooru();
                List<String> tags = await booru.getAllTags();
                final currentTags = List.from(controller.text.split(" "));
                final displayTags = List.from(tags);
                displayTags.retainWhere((s){
                        return s.contains(currentTags.last) && !currentTags.contains(s);
                });
                return displayTags.map((tag) => ListTile(
                    title: Text(tag),
                    onTap: () {
                        List endResult = List.from(currentTags);
                        endResult.removeLast();
                        endResult.add(tag);
                        setState(() => controller.closeView("${endResult.join(" ")} "));
                    },
                ));
            },
            viewTrailing: [
                IconButton(onPressed: _controller.clear, icon: const Icon(Icons.close)),
                _SearchButton(controller: _controller, onSearch: widget.onSearch)
            ],
        );
    }
}

class _SearchButton extends StatelessWidget {
    const _SearchButton({super.key, required this.controller, required this.onSearch, this.icon = const Icon(Icons.search)});

    final SearchController controller;
    final Widget icon;
    final Function(String) onSearch;
    
    @override
    Widget build(context) {
        return IconButton(
            icon: icon,
            onPressed: controller.text.isEmpty ? null : () => onSearch(controller.text),
        );
    }
}