import 'package:flutter/material.dart';

class Header extends StatelessWidget {
    const Header(this.title, {super.key, this.padding = const EdgeInsets.only(top: 16.0), this.color});

    final String title;
    final Color? color;
    final EdgeInsets padding;

    @override
    Widget build(BuildContext context) {
        return Padding(
            padding: padding,
            child: Text(title, style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: color
            )),
        );
    }
}

class SmallHeader extends StatelessWidget {
    const SmallHeader(this.title, {super.key, this.padding = const EdgeInsets.only(top: 16.0, left: 16.0), this.color});

    final String title;
    final Color? color;
    final EdgeInsets padding;

    @override
    Widget build(BuildContext context) {
        return Padding(
            padding: padding,
            child: Text(title, style: TextStyle(
                fontSize: 16.0,
                color: color ?? Theme.of(context).colorScheme.primary
            )),
        );
    }
}