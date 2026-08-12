import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import 'golib.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Go FFI on OHOS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Go FFI on OpenHarmony'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _result = 'Not called yet';

  @override
  void initState() {
    super.initState();
    // Call the Go library on startup so the result lands in the log without
    // any manual interaction.
    _result = _runGo();
  }

  String _runGo() {
    try {
      final int sum = Golib.instance.sum(3, 4);
      final String greeting = Golib.instance.greeting();
      final String msg = 'Go FFI OK: GoSum(3,4)=$sum, GoGreeting()="$greeting"';
      developer.log(msg, name: 'GoFFI');
      print('GOFFI|OK|$msg');
      return 'GoSum(3,4)=$sum\nGoGreeting()="$greeting"';
    } catch (e, st) {
      developer.log(
        'Go FFI FAILED: $e',
        name: 'GoFFI',
        error: e,
        stackTrace: st,
      );
      print('GOFFI|FAILED|$e');
      return 'FFI error: $e';
    }
  }

  void _callGo() {
    setState(() => _result = _runGo());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('Result from Go shared library:'),
              const SizedBox(height: 8),
              Text(
                _result,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _callGo,
                child: const Text('Call Go via FFI'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
