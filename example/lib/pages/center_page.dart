import 'package:flutter/material.dart';

class CenterPage extends StatelessWidget {
  const CenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        title: const Text('Center Page'),
      ),
      body: Center(
        child: Text(
          'This is the center page',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
