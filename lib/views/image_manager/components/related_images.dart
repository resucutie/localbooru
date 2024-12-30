import 'package:flutter/material.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/components/builders.dart';
import 'package:localbooru/components/image_grid_display.dart';

class RelatedImagesCard extends StatelessWidget {
    const RelatedImagesCard({super.key, required this.relatedImages, this.onRemove, this.onAddButtonPress, this.showBlockWarning = false});

    final List<ImageID> relatedImages;
    final bool showBlockWarning; //unused
    final Function(ImageID imageID)? onRemove;
    final Function()? onAddButtonPress;

    @override
    Widget build(BuildContext context) {
        return Card(
            clipBehavior: Clip.antiAlias,
            child: Stack(
                children: [
                    Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        width: double.infinity,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                SizedBox(
                                    height: 80,
                                    child: BooruLoader(
                                        builder: (context, booru) => ListView(
                                            scrollDirection: Axis.horizontal,
                                            padding: const EdgeInsets.symmetric(horizontal: 16),
                                            children: [
                                                ...relatedImages.map((e) => [BooruImageLoader(
                                                    key: ValueKey(e),
                                                    booru: booru,
                                                    id: e,
                                                    builder: (context, relatedImage) => ClipRRect(
                                                        borderRadius: const BorderRadius.all(Radius.circular(12)),
                                                        clipBehavior: Clip.antiAliasWithSaveLayer,
                                                        child: MouseRegion(
                                                            cursor: WidgetStateMouseCursor.clickable,
                                                            child: GestureDetector(
                                                                // onTap: () => setState(() => relatedImages.remove(e)),
                                                                onTap: () {if(onRemove != null) onRemove!(e);},
                                                                child: Stack(
                                                                    children: [
                                                                        ImageGrid(
                                                                            image: relatedImage,
                                                                            resizeSize: 300,
                                                                        ),
                                                                        Positioned(
                                                                            top: 0, left: 0, bottom: 0, right: 0,
                                                                            child: Container(
                                                                                color: Colors.black.withOpacity(0.6),
                                                                                child: const Center(
                                                                                    child: Icon(Icons.delete_outline, size: 28,),
                                                                                ),
                                                                            )
                                                                        ),
                                                                    ],
                                                                ),
                                                            ),
                                                        ),
                                                    ), 
                                                ), const SizedBox(width: 12,)],).expand((i) => i),
                    
                                                AspectRatio(
                                                    aspectRatio: 1,
                                                    child: IconButton(
                                                        icon: const Icon(Icons.add),
                                                        style: IconButton.styleFrom(
                                                            backgroundColor: Colors.black.withOpacity(0.4),
                                                            hoverColor: Colors.black.withOpacity(0.1),
                                                            shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(12)
                                                            )
                                                        ),
                                                        onPressed: onAddButtonPress,
                                                    ),
                                                )
                                            ]
                                        )
                                    ),
                                )
                            ],
                        ),
                    ),
                    if(showBlockWarning) Positioned.fill(
                        child: Container(
                            color: Colors.black.withOpacity(0.7),
                            padding: const EdgeInsets.all(16),
                            child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                    Text("Correlation is enabled", textAlign: TextAlign.center, style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white
                                    ),),
                                    SizedBox(height: 8,),
                                    Text("You enabled the option to all images that are bulk added to automatically correlate with each other", textAlign: TextAlign.center, style: TextStyle(
                                        color: Colors.white
                                    ),),
                                ],
                            ),
                        )
                    ),
                ],
            )
        );
    }
}