import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

final Map<String, List<ImageProvider>> displays = {
    "baba": [
        const AssetImage("assets/counter/baba/0.gif"),
        const AssetImage("assets/counter/baba/1.gif"),
        const AssetImage("assets/counter/baba/2.gif"),
        const AssetImage("assets/counter/baba/3.gif"),
        const AssetImage("assets/counter/baba/4.gif"),
        const AssetImage("assets/counter/baba/5.gif"),
        const AssetImage("assets/counter/baba/6.gif"),
        const AssetImage("assets/counter/baba/7.gif"),
        const AssetImage("assets/counter/baba/8.gif"),
        const AssetImage("assets/counter/baba/9.gif"),
    ]
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
            children: number.toString().trim().split("").map((e) => Image(
                image: displays[display]![int.parse(e)],
                height: height,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
            )).toList()
        );
    }
}