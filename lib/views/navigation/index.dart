import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/components/context_menu.dart';
import 'package:localbooru/utils/constants.dart';
import 'package:localbooru/views/image_manager/peripherals.dart';
import 'package:localbooru/views/image_manager/preset_api.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

class AddImageDropRegion extends StatefulWidget {
    const AddImageDropRegion({super.key, required this.child});

    final Widget child;

    @override
    State<AddImageDropRegion> createState() => _AddImageDropRegionState();
}

class _AddImageDropRegionState extends State<AddImageDropRegion> {
    bool _isDragAndDrop = false;

    @override
    Widget build(BuildContext context) {
        return DropRegion(
            formats: Formats.standardFormats,
            child: Stack(
                children: [
                    widget.child,
                    Positioned(
                        left: 8, right: 8, bottom: 8, top: 8,
                        child: AnimatedOpacity(
                            opacity: _isDragAndDrop ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: IgnorePointer(
                                child: DottedBorder(
                                    strokeWidth: 4,
                                    radius: const Radius.circular(24),
                                    borderType: BorderType.RRect,
                                    color: Theme.of(context).colorScheme.primary,
                                    strokeCap: StrokeCap.round,
                                    dashPattern: const [16, 16],
                                    child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 5.0),
                                        child: ClipRRect(
                                            borderRadius: const BorderRadius.all(Radius.circular(18)),
                                            child: Container(
                                                color: Color.alphaBlend(Theme.of(context).colorScheme.primary.withOpacity(0.4), Colors.black.withOpacity(0.4)),
                                                child: const Center(
                                                    child: Wrap(
                                                        direction: Axis.vertical,
                                                        crossAxisAlignment: WrapCrossAlignment.center,
                                                        spacing: 48,
                                                        children: [
                                                            Icon(Icons.add, size: 96,),
                                                            Text("Drag to add",style: TextStyle(fontSize: 36, color: Colors.white))
                                                        ],
                                                    ),
                                                ),
                                            ),
                                        ),
                                    ),
                                ),
                            ),
                        )
                    )
                ],
            ),
            onDropOver: (event) {
                final item = event.session.items.first;
                    
                if(item.localData is Map) return DropOperation.none; // it is a drag from inside the app, ignore;

                setState(() => _isDragAndDrop = true);

                if(event.session.allowedOperations.contains(DropOperation.copy)) return DropOperation.copy;
                else return DropOperation.none;
            },
            onDropLeave: (p0) => setState(() => _isDragAndDrop = false),
            onPerformDrop: (event) async {
                final item = event.session.items.first;
                final reader = item.dataReader!;
                debugPrint("got it, ${item.platformFormats}");
                
                final sentFormats = reader.getFormats(SuperFormats.all);
                if(sentFormats.isEmpty) {ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Unknown format dragged"))); return;}
                final SimpleFileFormat insertedFormat = sentFormats[0] as SimpleFileFormat;
                debugPrint("inserted format: $insertedFormat");

                // late StreamSubscription ss;
                reader.getFile(insertedFormat, (file) async {
                        final fileExtension = insertedFormat.mimeTypes!.first.split("/")[1];
                    final mmm = await cache.putFileStream("drag&Drop${file.fileName ?? ""}${file.fileSize}", file.getStream(), fileExtension: fileExtension);
                    debugPrint(mmm.path);
                    if(context.mounted) GoRouter.of(context).pushNamed("drag_path", pathParameters: {"path": mmm.path});
                }, onError: (error) {
                    debugPrint('Error reading value $error');
                });
            },
        );
    }
}

class DefaultDrawer extends StatelessWidget {
    const DefaultDrawer({super.key, this.activeView, this.displayTitle = true, this.desktopView = false});

    final bool displayTitle;
    final bool desktopView;
    final String? activeView;

    @override
    Widget build(context) {
        Color? assertSelected(String selectorView) {
            if(activeView == selectorView) return Theme.of(context).colorScheme.primary;
        }
        return ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
                SizedBox(height: MediaQuery.of(context).viewPadding.top),
                if(displayTitle) const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text("LocalBooru",
                        style: TextStyle(
                            fontSize: 20.0
                        )
                    ),
                ),
                if(desktopView) ...[
                    ListTile(
                        textColor: assertSelected("home"),
                        iconColor: assertSelected("home"),
                        title: const Text("Home"),
                        leading: const Icon(Icons.home),
                        onTap: activeView != "home" ? () {
                            Scaffold.of(context).closeDrawer();
                            context.go("/home");
                        } : null,
                    ),
                    ListTile(
                        textColor: assertSelected("recent") ?? assertSelected("search"),
                        iconColor: assertSelected("recent") ?? assertSelected("search"),
                        title: const Text("Search"),
                        leading: const Icon(Icons.search),
                        onTap: activeView != "recent" && activeView != "search" ? () {
                            Scaffold.of(context).closeDrawer();
                            context.push("/recent");
                        } : null,
                    ),
                    const Divider(),
                ],
                ListTile(
                    textColor: assertSelected("manage_image"),
                    iconColor: assertSelected("manage_image"),
                    title: const Text("Add image"),
                    leading: const Icon(Icons.add),
                    onTap: activeView != "manage_image" ? () {
                        Scaffold.of(context).closeDrawer();
                        context.push("/manage_image");
                    } : null,
                ),
                ListTile(
                    title: const Text("Import from service"),
                    leading: const Icon(Icons.link),
                    enabled: activeView != "manage_image",
                    onTap: () {
                        Scaffold.of(context).closeDrawer();
                        showDialog(
                            context: context,
                            builder: (context) {
                                return const InsertURLDialog();
                            },
                        );
                    },
                ),
                ListTile(
                    textColor: assertSelected("settings"),
                    iconColor: assertSelected("settings"),
                    title: const Text("Settings"),
                    leading: const Icon(Icons.settings),
                    onTap: activeView != "settings" ? () {
                        Scaffold.of(context).closeDrawer();
                        context.push("/settings");
                    } : null,
                ),
                if(kDebugMode) ...[
                    const Divider(),
                    const Padding(
                        padding: EdgeInsets.only(left: 16.0, top: 16.0),
                        child: Text("Dev mode"),
                    ),
                    ListTile(
                        title: const Text("Playground"),
                        onTap: () {
                            Scaffold.of(context).closeDrawer();
                            context.push("/playground");
                        },
                    ),
                    ListTile(
                        title: const Text("Go to permissions screen"),
                        onTap: () {
                            Scaffold.of(context).closeDrawer();
                            context.push("/permissions");
                        },
                    ),
                    ListTile(
                        title: const Text("Go to set booru screen"),
                        onTap: () {
                            Scaffold.of(context).closeDrawer();
                            context.push("/setbooru");
                        },
                    ),
                    ListTile(
                        title: const Text("Desktop size"),
                        onTap: () {
                            appWindow.size = const Size(1280, 720);
                        },
                    ),
                    ListTile(
                        title: const Text("Phone size"),
                        onTap: () {
                            appWindow.size = const Size(320, 840);
                        },
                    ),
                ]
            ],
        );
    }
}

class BrowseScreenPopupMenuButton extends StatelessWidget {
    const BrowseScreenPopupMenuButton({super.key, this.image});

    final BooruImage? image;

    @override
    Widget build(context) {
        return PopupMenuButton(
            // child: Icon(Icons.more_vert),
            itemBuilder: (context) {
                final List<PopupMenuEntry> filteredList = booruItems();
                if(image != null) {
                    filteredList.add(const PopupMenuDivider());
                    filteredList.addAll(imageShareItems(image!));
                    filteredList.add(const PopupMenuDivider());
                    filteredList.addAll(imageManagementItems(image!, context: context));
                };
                return filteredList;
            }
        );
    }
}