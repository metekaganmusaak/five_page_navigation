import 'package:flutter/material.dart';

class BottomPage extends StatelessWidget {
  const BottomPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amber,
      appBar: AppBar(
        title: const Text('Bottom Page'),
      ),
      body: Center(
        child: Text(
          'This is the bottom page',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
