import 'package:flutter/material.dart';
import 'package:localbooru/api/index.dart';

class ExternalImage extends StatelessWidget {
  final BooruImage image;
  final VoidCallback? onPressed;
  const ExternalImage({super.key, required this.image, this.onPressed});
  
  @override
  Widget build(BuildContext context) {
    return Container(
        //padding: const EdgeInsets.all(8),
        child: Image.file(image.getImage(), fit: BoxFit.cover),
    );
  }
}

class RepoGrid extends StatelessWidget {
    final List<BooruImage> images;
    final VoidCallback? onPressed;
    const RepoGrid({super.key, required this.images, this.onPressed});
  
    @override
    Widget build(BuildContext context) {
        if(images.isEmpty) {
            return const SizedBox.shrink();
        } else {
            return SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                ),
                delegate: SliverChildListDelegate(images.map((image) {
                    return Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: ExternalImage(image: image, onPressed: onPressed),
                    );
                }).toList()),
            );
        }
    }
}