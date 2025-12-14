import 'package:flutter/material.dart';

class DeviceScreen extends StatelessWidget {
  const DeviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eszköz'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Eszköz kezelés',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              const Text(
                'Itt jelennek meg a csatlakoztatott eszközök',
                style: TextStyle(fontSize: 16),
              ),
              // Itt jöhetnek majd az eszközök listája, csatlakoztatás, stb.
            ],
          ),
        ),
      ),
    );
  }
}

