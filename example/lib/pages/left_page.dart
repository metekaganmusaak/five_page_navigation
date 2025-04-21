import 'package:flutter/material.dart';

class LeftPage extends StatelessWidget {
  const LeftPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      appBar: AppBar(
        title: const Text('Left Page'),
      ),
      body: Center(
        child: Text(
          'This is the left page',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
