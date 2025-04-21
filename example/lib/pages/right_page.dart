import 'package:flutter/material.dart';

class RightPage extends StatelessWidget {
  const RightPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red,
      appBar: AppBar(
        title: const Text('Right Page'),
      ),
      body: Center(
        child: Text(
          'This is the right page',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
