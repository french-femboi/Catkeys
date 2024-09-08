import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main/home.dart';

void main() {
  runApp(const Settings());
}

class Settings extends StatelessWidget {
  const Settings({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Settings',
      themeMode: ThemeMode.system, // Use device's color scheme
      darkTheme: ThemeData.dark(), // Enable dark mode
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter', // Set the font family to Inter
      ),
      home: const SettingsPage(title: 'Settings'),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.title});

  final String title;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _postsController = TextEditingController();
  String dropdownValue = '100';

  @override
  void initState() {
    super.initState();
    fetchSettings();
  }

  @override
  void dispose() {
    _postsController.dispose();
    super.dispose();
  }

  navHome() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HomePage(title: 'Catkeys')),
    );
  }

  fetchSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _postsController.text = (prefs.getInt('catkeys_posts_shows').toString());
    });
  }

  vibrate() async {
    final can = await Haptics.canVibrate();
    if (!can) return;
    await Haptics.vibrate(HapticsType.warning);
  }

  savePostNumbers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (int.parse(_postsController.text) <= 100) {
      await prefs.setInt('catkeys_posts_shows', int.parse(_postsController.text));
      Fluttertoast.showToast(
        msg: "You'll see ${_postsController.text} posts on your home page!",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        textColor: Theme.of(context).colorScheme.onPrimaryContainer,
      );
    } else {
      Fluttertoast.showToast(
        msg: 'You cannot load more than 100 posts!',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        textColor: Theme.of(context).colorScheme.onErrorContainer,
      );
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
          title: Row(
            children: [
              GestureDetector(
                onTap: () {
                  vibrate();
                  navHome();
                },
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(width: 20),
              Text(
                widget.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
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
                            "This app is open-source and free to use. If you like it, consider starring the repository on GitHub! And also consider telling me some feedback, I'd love to hear from you!",
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
                SizedBox(height: 8),
                Divider(),
                SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Text(
                    'Shown posts',
                    style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Text(
                    'Control the number of posts shown on your home page.',
                    style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _postsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter a number',
                      border: OutlineInputBorder(), // Add border to the text field
                    ),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                  onPressed: () {
                    vibrate();
                    savePostNumbers();
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainer,
                    padding: const EdgeInsets.symmetric(vertical: 6),
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
                SizedBox(height: 8),
                Divider(),
                SizedBox(height: 8),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
