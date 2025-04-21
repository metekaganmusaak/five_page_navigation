import 'package:flutter/material.dart';

class TopPage extends StatelessWidget {
  const TopPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      appBar: AppBar(
        title: const Text('Top Page'),
      ),
      body: Center(
        child: Text(
          'This is the top page',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
