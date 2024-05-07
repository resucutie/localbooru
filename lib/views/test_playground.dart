import 'package:flutter/material.dart';

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
            body: Image.asset("assets/", height: 48, width: 48, fit: BoxFit.contain,)
        );
    }
}
