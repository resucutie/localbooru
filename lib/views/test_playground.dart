import 'package:flutter/material.dart';
import 'package:localbooru/components/counter.dart';

class TestPlaygroundScreen extends StatefulWidget {
    const TestPlaygroundScreen({super.key});

    @override
    State<TestPlaygroundScreen> createState() => _TestPlaygroundScreenState();
}

class _TestPlaygroundScreenState extends State<TestPlaygroundScreen> {
    @override
    Widget build(context) {
        return Scaffold(
            appBar: AppBar(
                title: const Text("Playground"),
            ),
            body: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    Center(
                        child: Wrap(
                            spacing: 8,
                            children: List.filled(5, Image.asset("assets/Screenshot_1009.webp", width: 64, fit: BoxFit.contain, filterQuality: FilterQuality.none,))
                        )
                    ),
                    const StyleCounter(number: 12345, display: "squares",),
                    const StyleCounter(number: 67890, display: "baba",),
                ],
            )
        );
    }
}
