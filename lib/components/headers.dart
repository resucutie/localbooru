import 'package:flutter/material.dart';

class Header extends StatelessWidget {
    const Header(this.title, {super.key, this.padding = const EdgeInsets.only(top: 16.0)});

    final String title;
    final EdgeInsets padding;

    @override
    Widget build(BuildContext context) {
        return Padding(
            padding: padding,
            child: Text(title, style: const TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold
            )),
        );
    }
}

class SmallThemedHeader extends StatelessWidget {
    const SmallThemedHeader(this.title, {super.key, this.padding = const EdgeInsets.only(top: 16.0, left: 16.0)});

    final String title;
    final EdgeInsets padding;

    @override
    Widget build(BuildContext context) {
        return Padding(
            padding: padding,
            child: Text(title, style: TextStyle(
                fontSize: 16.0,
                // fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary
            )),
        );
    }
}