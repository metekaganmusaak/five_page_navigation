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
      body: ListView.builder(
        itemCount: 100,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            title: Text('Item $index'),
            onTap: () {
              // Handle item tap
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Tapped on Item $index')),
              );
            },
          );
        },
      ),
    );
  }
}
