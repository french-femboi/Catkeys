import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

import '../main/home.dart';

void main() {
  runApp(const Setup());
}

class Setup extends StatelessWidget {
  const Setup({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catkeys setup',
      themeMode: ThemeMode.system, // Use device's color scheme
      darkTheme: ThemeData.dark(), // Enable dark mode
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter', // Set the font family to Inter
      ),
      home: const SetupPage(title: 'Catkeys setup'),
    );
  }
}

class SetupPage extends StatefulWidget {
  const SetupPage({super.key, required this.title});

  final String title;

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  navHome() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HomePage(title: 'Catkeys')),
    );
  }

  checkInstance() {
    String url = _urlController.text;
    String token = _tokenController.text;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Please confirm'),
          content: Text('URL: $url\n\nTOKEN: $token'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                saveData(url, token);
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  saveData(String url, String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('catkeys_url', url);
    await prefs.setString('catkeys_token', token);
    await prefs.setInt('catkeys_posts_shows', 250);
    await prefs.setBool('catkeys_haptics', true);
    navHome();
  }

  vibrateSelection() async {
            final hasCustomVibrationsSupport = await Vibration.hasCustomVibrationsSupport();
      if (hasCustomVibrationsSupport != null && hasCustomVibrationsSupport) {
          Vibration.vibrate(duration: 50);
      } else {
          Vibration.vibrate();
          await Future.delayed(Duration(milliseconds: 50));
          Vibration.vibrate();
      }
    
  }

  vibrateError() async {
            final hasCustomVibrationsSupport = await Vibration.hasCustomVibrationsSupport();
      if (hasCustomVibrationsSupport != null && hasCustomVibrationsSupport) {
          Vibration.vibrate(duration: 200);
      } else {
          Vibration.vibrate();
          await Future.delayed(Duration(milliseconds: 200));
          Vibration.vibrate();
      }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        return Future.value(false);
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
          title: Text(
            widget.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          automaticallyImplyLeading: false, // Remove back button
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Center(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.start, // Align text to the start (left)
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Align text to the start (left)
              children: [
                const SizedBox(height: 25),
                Text(
                  'Welcome to Catkeys!',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  textAlign: TextAlign.start, // Align text to the start (left)
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start, // Align children to the top
                      children: [
                        Icon(
                          Icons.info_rounded,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Haii haii, I'm French Femboi and I made this Misskey client, because I didn't find any client that fit my needs. I am in no way related with Misskey!",
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.secondary,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.start,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start, // Align children to the top
                      children: [
                        Icon(
                          Icons.warning_rounded,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Keep in mind this app connects you to a Misskey instance. I am not responsible for any content you may see or post.",
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.secondary,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.start,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Please put in the url of your Misskey instance, and an API key, that you've generated in Settings > API > Generate access token make sure to just put in the domain name without http:// or https://!",
                  style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _urlController,
                          keyboardType: TextInputType.url,
                          decoration: const InputDecoration(
                            labelText: 'URL without https://',
                            hintText: 'Enter the URL of your Misskey instance',
                          ),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: _tokenController,
                          decoration: InputDecoration(
                            labelText: 'Token',
                            hintText: 'Enter your freshly generated API token',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    vibrateError();
                    checkInstance();
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainer,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 0),
                  ),
                  child: Text(
                    'Save',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
