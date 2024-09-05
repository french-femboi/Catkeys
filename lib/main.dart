import 'package:catkeys/pre/setup.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main/home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catkeys',
      themeMode: ThemeMode.system, // Use device's color scheme
      darkTheme: ThemeData.dark(), // Enable dark mode
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: 'Inter', // Set the font family to Inter
      ),
      home: const MyHomePage(title: 'Catkeys'),
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

  @override
  void initState() {
    super.initState();
    initializeWindow(context);
  }

  Future<void> initializeWindow(BuildContext context) async {
    await Future.delayed(const Duration(seconds: 2));
    checkData();
  }

  navSetup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SetupPage(title: 'Catkeys setup')),
    );
  }

  navHome() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HomePage(title: 'Catkeys')),
    );
  }

  checkData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool catkeysInstanceExists = prefs.containsKey('catkeys_url');
    if (catkeysInstanceExists) {
      navHome();
    } else {
      navSetup();
    }
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          widget.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.surface,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
              Image.asset(
                'assets/img/logo.png',
                width: 100,
                height: 100,
              ),
            Text(
              'Catkeys',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Made with <3 by French Femboi',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.w500
              ),
            ),
          ],
        ),
      ),
    );
  }
}
