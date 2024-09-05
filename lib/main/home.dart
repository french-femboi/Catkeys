import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:mimi/mimi.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../pre/setup.dart';

void main() {
  runApp(const Home());
}

class Home extends StatelessWidget {
  const Home({super.key});

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
      home: const HomePage(title: 'Catkeys'),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String url = '';
  String token = '';
  int currentPageIndex = 0;
  String profilePicture = '';
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  fetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      url = prefs.getString('catkeys_url') ?? '';
      token = prefs.getString('catkeys_token') ?? '';
    });
    if (url.isNotEmpty && token.isNotEmpty) {
        final host = url;
        final client = Client(host);
        
    }
  }

  lookupAccount() async {}

  @override
  void dispose() {
    super.dispose();
  }

  vibrate() async {
    final can = await Haptics.canVibrate();
    if (!can) return;
    await Haptics.vibrate(HapticsType.warning);
  }

  vibrateSel() async {
    final can = await Haptics.canVibrate();
    if (!can) return;
    await Haptics.vibrate(HapticsType.success);
  }

  createNote() async {}

  clearData() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('catkeys_url');
      prefs.remove('catkeys_token');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => const SetupPage(title: 'Catkeys setup')),
      );
    });
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
          actions: [
            PopupMenuButton(
              itemBuilder: (BuildContext context) {
                return [
                  const PopupMenuItem(
                    value: 'Settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings_rounded),
                        SizedBox(width: 10),
                        Text('Settings'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'Source Code',
                    child: Row(
                      children: [
                        Icon(Icons.source_rounded),
                        SizedBox(width: 10),
                        Text('Source Code'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'Log Out',
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded),
                        SizedBox(width: 10),
                        Text('Log Out'),
                      ],
                    ),
                  ),
                ];
              },
              onSelected: (value) {
                if (value == 'Settings') {
                  // Do something for option 1
                } else if (value == 'Source Code') {
                  // Do something for option 2
                } else if (value == 'Log Out') {
                  vibrate();
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Logging Out'),
                        content: const Text(
                            "Are you sure you want to log out? This won't clear your settings."),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              vibrateSel();
                            },
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              clearData();
                              vibrateSel();
                            },
                            child: const Text('Confirm'),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
            ),
          ],
        ),
        body: const SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Center(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.start, // Align text to the start (left)
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Align text to the start (left)
              children: [
                SizedBox(height: 25),
              ],
            ),
          ),
        ),
        floatingActionButton: currentPageIndex == 0
            ? FloatingActionButton(
                onPressed: () {
                  vibrateSel();
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Create a note'),
                        content: Column(
                          children: [
                            SingleChildScrollView(
                              child: TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Note',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: null,
                                controller: _noteController,
                                scrollPhysics:
                                    const NeverScrollableScrollPhysics(),
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              vibrateSel();
                              Navigator.of(context).pop();
                            },
                            child: const Text('Post'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: const Icon(Icons.edit_rounded),
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainer, // Customize the background color here
              )
            : null,
        bottomNavigationBar: SizedBox(
          height: 60, // Adjust the height as desired
          child: NavigationBar(
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            selectedIndex: currentPageIndex,
            onDestinationSelected: (int index) {
              vibrateSel();
              setState(() {
                currentPageIndex = index;
              });
            },
            destinations: <Widget>[
              const NavigationDestination(
                icon: Icon(Icons.explore),
                label: 'Explore',
              ),
              const NavigationDestination(
                selectedIcon: Icon(Icons.notifications_rounded),
                icon: Icon(Icons.notifications_outlined),
                label: 'Notifications',
              ),
              const NavigationDestination(
                icon: Icon(Icons.search_rounded),
                label: 'Search',
              ),
              NavigationDestination(
                selectedIcon: CircleAvatar(
                  backgroundImage: NetworkImage(profilePicture),
                  radius: 16, // Adjust the radius to make the image smaller
                ),
                icon: CircleAvatar(
                  backgroundImage: NetworkImage(profilePicture),
                  radius: 16, // Adjust the radius to make the image smaller
                ),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
