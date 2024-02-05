import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/views/tagbrowse.dart';

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