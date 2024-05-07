import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

final Map<String, List<String>> displays = {
    "baba": ["assets/counter/baba", "gif"], //AssetImage for images/gifs
    "squares": ["assets/counter/squares", "svg"] //ExactAssetPicture for svg
};

class StyleCounter extends StatelessWidget {
    const StyleCounter({super.key, required this.number, this.display = "baba", this.height = 48});

    final int number;
    final double height;
    final String display;

    @override
    Widget build(context) {
        return Wrap(
            direction: Axis.horizontal,
            spacing: 8,
            alignment: WrapAlignment.center,
            children: number.toString().trim().split("").map((e) {
                final info = displays[display]!;
                final file = "${info[0]}/$e.${info[1]}";
                if(info[1] == "svg") return SvgPicture.asset(file,
                    height: height,
                    fit: BoxFit.contain,
                    // color: Theme.of(context).colorScheme.primary,
                    theme: SvgTheme(
                        currentColor: Theme.of(context).colorScheme.primary
                    ),
                );
                return Image.asset(file,
                    height: height,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.none,
                );
            }).toList()
        );
    }
}