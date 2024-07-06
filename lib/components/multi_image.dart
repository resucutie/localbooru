import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class MultipleImage extends StatelessWidget {
    const MultipleImage({super.key, required this.images});

    final List<ImageProvider?> images;

    @override
    Widget build(BuildContext context) {
        return Stack(
            children: [
                Positioned.fill(
                    child: Opacity(
                        opacity: 0.3,
                        child: MultipleImageImageBox(
                            alignment: FractionalOffset.bottomRight,
                            image: images[2],
                        ),
                    ),
                ),
                Positioned.fill(
                    child: Opacity(
                        opacity: 0.8,
                        child: MultipleImageImageBox(
                            alignment: FractionalOffset.center,
                            image: images[1],
                        ),
                    ),
                ),
                Positioned.fill(
                    child: Opacity(
                        opacity: 1,
                        child: MultipleImageImageBox(
                            alignment: FractionalOffset.topLeft,
                            image: images[0],
                        ),
                    ),
                ),
            ],
        );
    }
}

class MultipleImageImageBox extends StatelessWidget {
    const MultipleImageImageBox({super.key, required this.image, this.alignment = Alignment.center});

    final ImageProvider? image;
    final AlignmentGeometry alignment;


    @override
    Widget build(BuildContext context) {
        final Color blankCardColor = Theme.of(context).colorScheme.surfaceContainer;
        return FractionallySizedBox(
            widthFactor: 0.8,
            heightFactor: 0.8,
            alignment: alignment,
            child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                    color: image != null ?  blankCardColor.withOpacity(0.5) : blankCardColor,
                    child: image != null ? Image(
                        image: image!,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.none,
                    ) : null,
                ),
            )
        );
    }
}