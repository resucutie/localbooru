import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/components/builders.dart';
import 'package:localbooru/components/housings.dart';
import 'package:localbooru/components/window_frame.dart';
import 'package:localbooru/main.dart';
import 'package:localbooru/utils/constants.dart';
import 'package:localbooru/utils/shared_prefs_widget.dart';
import 'package:localbooru/views/about.dart';
import 'package:localbooru/views/image_manager/shell.dart';
import 'package:localbooru/views/lock.dart';
import 'package:localbooru/views/navigation/collection_list.dart';
import 'package:localbooru/views/navigation/home.dart';
import 'package:localbooru/views/navigation/image_view.dart';
import 'package:localbooru/views/navigation/index.dart';
import 'package:localbooru/views/navigation/tag_browse.dart';
import 'package:localbooru/views/navigation/zoomed_view.dart';
import 'package:localbooru/views/permissions.dart';
import 'package:localbooru/views/set_booru.dart';
import 'package:localbooru/views/settings/booru_settings/collections.dart';
import 'package:localbooru/views/settings/booru_settings/index.dart';
import 'package:localbooru/views/settings/booru_settings/tag_types.dart';
import 'package:localbooru/views/settings/index.dart';
import 'package:localbooru/views/settings/overall_settings.dart';
import 'package:localbooru/views/test_playground.dart';
import 'package:shared_preferences/shared_preferences.dart';

final router = GoRouter(
    initialLocation: '/home',
    routes: [
        GoRoute(path: '/',
            redirect: (context, GoRouterState state) async {
                final hasPerms = await hasExternalStoragePerms();
                final prefs = await SharedPreferences.getInstance();
                
                if (!hasPerms) return "/permissions";
                if (prefs.getString("booruPath") == null) return "/setbooru";

                return null;
            },
            routes: [
                ShellRoute(
                    builder: (context, state, child) => SharedPreferencesBuilder(
                        builder: (context, prefs) {
                            return Scaffold(
                                backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                                appBar: prefs.getBool("custom_frame") ?? settingsDefaults["custom_frame"] ? const PreferredSize(
                                    preferredSize: Size.fromHeight(32),
                                    child: WindowFrameAppBar()
                                ) : null,
                                body: LockScreen(child: child),
                            );
                        },
                        loading: const SizedBox(height: 0,)
                    ),
                    routes: [
                        ShellRoute(
                            builder: (context, state, child) => MediaQuery.of(context).orientation == Orientation.landscape ? SharedPreferencesBuilder(
                                builder: (context, prefs) => DesktopHousing(routeUri: state.uri, roundedCorners: prefs.getBool("custom_frame") ?? settingsDefaults["custom_frame"], child: child,),
                                loading: const SizedBox(height: 0,),
                            ) : MobileHousing(child: child),
                            routes: [
                                ShellRoute( //main nav shell
                                    builder: (context, state, child) => AddImageDropRegion(child: child),
                                    routes: [
                                        GoRoute(path: "home",
                                            builder: (context, state) => const HomePage(),
                                        ),
                                        GoRoute(path: "search",
                                            builder: (context, state) {
                                                final String tags = state.uri.queryParameters["tag"] ?? "";
                                                final String? index = state.uri.queryParameters["index"];
                                                return GalleryViewer(
                                                    searcher: (index) async {
                                                        SharedPreferences prefs = await SharedPreferences.getInstance();
                                                        final Booru booru = await getCurrentBooru();
                                                        int indexSize = prefs.getInt("page_size") ?? settingsDefaults["page_size"];

                                                        int indexLength = await booru.getIndexNumberLength(tags, size: indexSize);
                                                        List<BooruImage> images = await booru.searchByTags(tags, index: index, size: indexSize);
                                                        return SearchableInformation(images: images, indexLength: indexLength);
                                                    },
                                                    displayBackButton: false,
                                                    index: int.parse(index ?? "0"),
                                                    onNextPage: (newIndex) => context.push("/search?tag=$tags&index=$newIndex"),
                                                    headerDisplay: (context, orientation) => SearchBarOnGridList(
                                                        onSearch: (tags) => context.push("/search?tag=$tags"),
                                                        desktopDisplay: orientation == Orientation.landscape,
                                                        initialText: tags,
                                                    ),
                                                    actions: [
                                                        IconButton(
                                                            icon: const Icon(Icons.add),
                                                            tooltip: "Add image",
                                                            onPressed: () => context.push("/manage_image"),
                                                        ),
                                                    ],
                                                );
                                            }
                                        ),
                                        GoRoute(path: "recent", redirect: (_, __) => '/search',),
                                        // ShellRoute(
                                        //     builder: (context, state, child) {
                                        //         final String? id = state.pathParameters["id"];
                                        //         if (id == null) return Text("Invalid ID $id");
                                                        
                                        //         return BooruLoader( builder: (_, booru) => BooruImageLoader(
                                        //             booru: booru,
                                        //             id: id,
                                        //             builder: (context, image) {
                                        //                 return ImageViewShell(image: image, shouldShowImageOnPortrait: state.fullPath == "/view/:id", child: child,);
                                        //             }
                                        //         ));
                                        //     },
                                        //     routes: [
                                        //     ]
                                        // ), 
                                        GoRoute(path: "view/:id",
                                            builder: (context, state) {
                                                final String? id = state.pathParameters["id"];
                                                if (id == null) return Text("Invalid ID $id");

                                                future() async {
                                                    final booru = await getCurrentBooru();
                                                    final image = await booru.getImage(id);
                                                    final collectionList = await booru.obtainMatchingCollection(id);
                                                    return {
                                                        'image': image,
                                                        'collections': collectionList
                                                    };
                                                }

                                                return FutureBuilder(
                                                    future: future(),
                                                    builder: (context, snapshot) {
                                                        if(snapshot.hasData) {
                                                            BooruImage image = snapshot.data!['image'] as BooruImage;
                                                            List<BooruCollection> collections = snapshot.data!['collections'] as List<BooruCollection>;
                                                            return ImageViewShell(
                                                                image: image,
                                                                shouldShowImageOnPortrait: true,
                                                                collections: collections,
                                                                child: ImageViewProprieties(image),
                                                            );
                                                        }
                                                        return const Center(child: CircularProgressIndicator(),);
                                                    },
                                                );
                                            },
                                            routes: [
                                                GoRoute(path: "note",
                                                    builder: (context, state) {
                                                        final String? id = state.pathParameters["id"];
                                                        if(id == null || int.tryParse(id) == null) return Text("Invalid ID $id");

                                                        return BooruLoader( builder: (_, booru) => BooruImageLoader(
                                                            booru: booru,
                                                            id: id,
                                                            builder: (context, image) {
                                                                return ImageViewShell(image: image, shouldShowImageOnPortrait: true, child: NotesView(id: int.parse(id)),);
                                                            }
                                                        ));
                                                    },
                                                )
                                            ]
                                        ),
                                        GoRoute(path: "collections",
                                            builder: (context, state) {
                                                return BooruLoader(builder: (_, booru) => CollectionsListPage(booru: booru,));
                                            },
                                            routes: [
                                                GoRoute(path: ":id",
                                                    builder: (context, state) {
                                                        final String? id = state.pathParameters["id"];
                                                        if (id == null) return Text("Invalid ID $id");
                                                        final String? index = state.uri.queryParameters["index"];
                                                        return GalleryViewer(
                                                            searcher: (index) async {
                                                                SharedPreferences prefs = await SharedPreferences.getInstance();
                                                                final Booru booru = await getCurrentBooru();
                                                                final collection = (await booru.getCollection(id))!;
                                                                int indexSize = prefs.getInt("page_size") ?? settingsDefaults["page_size"];

                                                                // getRange
                                                                final int length = collection.pages.length;
                                                                int from = length - (indexSize * (index + 1));
                                                                int to = length - (indexSize * index);
                                                                if(from < 0) from = 0;
                                                                if(to < 0) to = length;
                                                                final rangedPageList = collection.pages.getRange(from, to);
                                                                
                                                                final List<BooruImage> images = await Future.wait(rangedPageList.map((id) async => (await booru.getImage(id))!));
                                                                return SearchableInformation(images: images, indexLength: (length / indexSize).ceil());
                                                            },
                                                            index: int.parse(index ?? "0"),
                                                            onNextPage: (newIndex) => context.push("/collections/$id/?index=$newIndex"),
                                                            headerDisplay: (context, orientation) {
                                                                return BooruLoader(builder: (_, booru) => FutureBuilder(
                                                                    future: booru.getCollection(id),
                                                                    builder: (context, snapshot) {
                                                                        if(!snapshot.hasData) return const Text("Loading");
                                                                        return ListTile(
                                                                            title: Text(snapshot.data!.name, style: const TextStyle(fontSize: 20.0)),
                                                                            subtitle: Text("Collection ID ${snapshot.data!.id}", style: const TextStyle(fontSize: 14.0)),
                                                                        );
                                                                    }
                                                                ));
                                                            },
                                                            additionalMenuOptions: [
                                                                PopupMenuItem(
                                                                    child: const Text("Edit collection"),
                                                                    onTap: () => context.push("/settings/booru/collections?id=$id")
                                                                )
                                                            ],
                                                            forceOrientation: Orientation.portrait,
                                                            actions: [
                                                                IconButton(
                                                                    icon: const Icon(Icons.add_photo_alternate_outlined),
                                                                    tooltip: "Add image",
                                                                    onPressed: () => context.push("/settings/booru/collections?id=$id"),
                                                                ),
                                                            ],
                                                        );
                                                    }
                                                ),
                                                // GoRoute(path: ":id",
                                                //     builder: (context, state) {
                                                //         final String? id = state.pathParameters["id"];
                                                //         if (id == null) return Text("Invalid ID $id");
                                                //         final String? index = state.uri.queryParameters["index"];

                                                //         return BooruLoader(builder: (_, booru) => FutureBuilder(
                                                //             future: booru.getCollection(id),
                                                //             builder: (context, snapshot) {
                                                //                 if(!snapshot.hasData) return const Center(child: CircularProgressIndicator(),);
                                                //                 return CollectionView(
                                                //                     booru: booru,
                                                //                     collection: snapshot.data!,
                                                //                     index: int.parse(index ?? "0"),
                                                //                 );
                                                //             }
                                                //         ));
                                                //     },
                                                // )
                                            ]
                                        ),
                                    ]
                                ),
                                // navigation


                                // image add
                                // i wish i could use shellroute for this but apparently i cant easily without making janky code
                                GoRoute(path: "manage_image",
                                    builder: (context, state) {
                                        return ImageManagerShell(
                                            // shouldOpenRecents: true,
                                            sendable: state.extra as ManageImageSendable?,
                                        );
                                    }
                                ),

                                // settings
                                ShellRoute(
                                    builder: (context, state, child) => SettingsShell(child: child),
                                    routes: [
                                        GoRoute(path: "settings",
                                            builder: (context, state) => const SettingsHome(),
                                            routes: [
                                                GoRoute(path: "overall_settings",
                                                    builder: (context, state) => SharedPreferencesBuilder(
                                                        builder: (context, prefs) => OverallSettings(prefs: prefs)
                                                    ),
                                                ),
                                                GoRoute(path: "booru",
                                                    builder: (context, state) => SharedPreferencesBuilder(
                                                        builder: (context, prefs) => BooruLoader(
                                                            builder: (context, booru) => BooruSettings(prefs: prefs, booru: booru,),
                                                        )
                                                    ),
                                                    routes: [
                                                        GoRoute(path: "tag_types",
                                                            builder: (context, state) => BooruLoader(
                                                                builder: (context, booru) => TagTypesSettings(booru: booru),
                                                            ),
                                                        ),
                                                        GoRoute(path: "collections",
                                                            builder: (context, state) => BooruLoader(
                                                                builder: (context, booru) => CollectionsSettings(booru: booru, jumpToCollection: state.uri.queryParameters["id"],),
                                                            ),
                                                        )
                                                    ]
                                                )
                                            ]
                                        )
                                    ]
                                ),
                                GoRoute(path: "about",
                                    builder: (context, state) => const AboutScreen(),
                                ),
                            ]
                        ),

                        // initial setup stuff
                        GoRoute(path: "permissions",
                            builder: (context, state) => const PermissionsScreen(),
                        ),
                        GoRoute(path: "setbooru",
                            builder: (context, state) => const SetBooruScreen(),
                        ),
                        GoRoute(path: "playground",
                            builder: (context, state) => const TestPlaygroundScreen(),
                        ),
                    ]
                ),
                GoRoute(path: "zoom_image/:id",
                    pageBuilder: (context, state) {
                        final String? id = state.pathParameters["id"];
                        if (id == null) return MaterialPage(child: Text("Invalid ID $id"));
                        return CustomTransitionPage(
                            transitionDuration: const Duration(milliseconds: 200),
                            key: state.pageKey,
                            child: BooruLoader(builder: (_, booru) => BooruImageLoader(
                                booru: booru,
                                id: id,
                                builder: (context, image) => ImageViewZoom(image),
                            )),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                return FadeTransition(
                                    opacity: animation,
                                    child: child,
                                );
                            },
                        );
                    }
                ),
            ]
        ),
    ]
);