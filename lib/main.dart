import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mem_tile/ui/memorytile.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memory Tile Game',
      home: MemoryTileGame(),
    );
  }
}
