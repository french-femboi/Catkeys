import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:misskey_dart/misskey_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main/home.dart';

void main() {
  runApp(const Profile());
}

class Profile extends StatelessWidget {
  const Profile({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'User profile',
      themeMode: ThemeMode.system, // Use device's color scheme
      darkTheme: ThemeData.dark(), // Enable dark mode
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter', // Set the font family to Inter
      ),
      home: const ProfilePage(title: 'User profile'),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.title});

  final String title;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Misskey client;
  String url = '';
  String token = '';
  String profilePicture = '';
  String profileBanner = '';
  String userName = '-';
  String userHandle = '-';
  String userFollowers = '-';
  String userFollowing = '-';
  String userNotes = '-';
  String userDescription = '-';
  String userStatus = '-';
  String uID = '-';
  String userInstance = '-';

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  navHome() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HomePage(title: 'Catkeys')),
    );
  }

  fetchUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
  }

  fetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      url = prefs.getString('catkeys_url') ?? '';
      token = prefs.getString('catkeys_token') ?? '';
      uID = prefs.getString('catkeys_view_user') ?? '';
    });
    if (url.isNotEmpty && token.isNotEmpty) {
      client = Misskey(
        host: url,
        token: token,
      );
      lookupAccount();
    }
  }

  lookupAccount() async {
    try {
      final res = await client.users.show(
        UsersShowRequest(
          userId: uID, // Replace with the actual user ID
        ),
      );
      print(res);

      setState(() {
        profilePicture = res.avatarUrl.toString(); // Null check
        profileBanner = res.bannerUrl?.toString() ?? '';
        userName = res.name?.toString() ?? 'Unknown';
        userHandle = res.username.toString();
        userFollowers = res.followersCount.toString();
        userFollowing = res.followingCount.toString();
        userNotes = res.notesCount.toString();
        userDescription = res.description?.toString() ?? 'No description';
        userStatus = res.onlineStatus?.toString() ?? 'Offline';
        userInstance = res.host?.toString() ?? url;
      });
    } catch (e) {
      print('Error: $e'); // Catch and print any errors
    }
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

  openLink(urlInput) async {
    var url = urlInput;
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      Fluttertoast.showToast(
        msg: 'There while launching a browser!',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        backgroundColor: Theme.of(context).colorScheme.onErrorContainer,
        textColor: Theme.of(context).colorScheme.error,
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
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Center(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.start, // Align text to the start (left)
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Align text to the start (left)
              children: [
                Column(
                  mainAxisSize: MainAxisSize
                      .min, // Ensure the Column doesn't expand infinitely
                  children: [
                    Container(
                      width: double.infinity,
                      height: 200, // Set a fixed height for the banner
                      child: Stack(
                        fit: StackFit
                            .expand, // Ensure the stack and its children fill the available space
                        children: [
                          // Banner image
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image:
                                    CachedNetworkImageProvider(profileBanner),
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                              ),
                            ),
                          ),
                          // Gradient overlay
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context)
                                      .colorScheme
                                      .surfaceContainer
                                      .withOpacity(0.9),
                                  Colors.transparent
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                          ),
                          // Content
                          Column(
                            children: [
                              const SizedBox(height: 30),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const SizedBox(width: 30),
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainer,
                                        width: 3,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      backgroundImage:
                                          CachedNetworkImageProvider(
                                              profilePicture),
                                      radius: 65,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '@$userHandle - $userInstance',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Status: ${userStatus == "OnlineStatus.online" ? "Online" : userStatus == "OnlineStatus.offline" ? "Offline" : userStatus == "OnlineStatus.active" ? "Active" : userStatus == "OnlineStatus.unknown" ? "Unknown" : userStatus}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Divider(),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Column(
                                  children: [
                                    Icon(Icons.edit_note_rounded,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary),
                                    const SizedBox(height: 8),
                                    Text('Notes',
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondary)),
                                    const SizedBox(height: 4),
                                    Text(userNotes,
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondary)), // Replace '200' with the actual value
                                  ],
                                ),
                                const SizedBox(width: 28),
                                Column(
                                  children: [
                                    Icon(Icons.person_add_rounded,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary),
                                    const SizedBox(height: 8),
                                    Text('Following',
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondary)),
                                    const SizedBox(height: 4),
                                    Text(userFollowing,
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondary)), // Replace '200' with the actual value
                                  ],
                                ),
                                const SizedBox(width: 28),
                                Column(
                                  children: [
                                    Icon(Icons.people_rounded,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary),
                                    const SizedBox(height: 8),
                                    Text('Followers',
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondary)),
                                    const SizedBox(height: 4),
                                    Text(userFollowers,
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondary)), // Replace '100' with the actual value
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            const Divider(),
                            const SizedBox(height: 10),
                            MarkdownBody(
                              data: userDescription ??
                                  'No description available', // Markdown text
                              styleSheet: MarkdownStyleSheet(
                                p: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondary, // Text style
                                ),
                              ),
                              onTapLink: (text, url, title) {
                                if (url != null) {
                                  openLink(url); // Open the link when tapped
                                }
                              },
                            ),
                            const SizedBox(height: 10),
                            const Divider(),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {
                                vibrateSel();
                                if (url == userInstance) {
                                  openLink('https://$url/@$userHandle');
                                } else {
                                  openLink(
                                      'https://$url/@$userHandle@$userInstance');
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor:
                                    Theme.of(context).colorScheme.secondary,
                                backgroundColor: Colors
                                    .transparent, // Set the button's text color
                                side: BorderSide(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary), // Add a border to the button
                                minimumSize: const Size(double.infinity,
                                    40), // Set the button's width to full width and height to 40
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons
                                      .open_in_browser_rounded), // Add your desired icon
                                  SizedBox(
                                      width:
                                          8), // Add some spacing between the icon and text
                                  Text(
                                      'Open profile in browser'), // Add your desired text
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    // Add more profile content here
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
