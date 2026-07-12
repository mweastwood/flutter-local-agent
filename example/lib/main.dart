import 'package:flutter/material.dart';
import 'package:local_agent/local_agent.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _aiStatus = 'Unknown';
  final _aiService = MockAiService();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    final status = await _aiService.checkStatus();
    if (!mounted) return;

    setState(() {
      _aiStatus = status.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Local Agent Plugin Example')),
        body: Center(child: Text('AI Core Status: $_aiStatus\n')),
      ),
    );
  }
}
