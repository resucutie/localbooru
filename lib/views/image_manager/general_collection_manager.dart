import 'package:flutter/material.dart';

class GeneralCollectionManagerScreen extends StatefulWidget {
  const GeneralCollectionManagerScreen({super.key});

  @override
  State<GeneralCollectionManagerScreen> createState() => _GeneralCollectionManagerScreenState();
}

class _GeneralCollectionManagerScreenState extends State<GeneralCollectionManagerScreen> {
    int count = 0;

    @override
    Widget build(BuildContext context) {
        return Column(
            children: [
                FilledButton(onPressed: () => setState(() => count++), child: Text("hi $count"))
            ],
        );
    }
}