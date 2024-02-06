import 'package:flutter/material.dart';

class Header extends StatelessWidget {
    const Header(this.title, {super.key});

    final String title;

    @override
    Widget build(BuildContext context) {
        return Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Text(title, style: const TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold
            )),
        );
    }
}