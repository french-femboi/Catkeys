// ignore_for_file: use_build_context_synchronously

import 'package:cached_network_image/cached_network_image.dart';
import 'package:catkeys/main/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:misskey_dart/misskey_dart.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';

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
  late Misskey client;
  String url = '';
  String token = '';
  int currentPageIndex = 0;
  String profilePicture =
      'https://cd.catpawz.eu/03-CATPAWZ/03.06%20-%20CATKEYS%20BUILDS/default-profile.png';
  String profileBanner =
      'https://cd.catpawz.eu/03-CATPAWZ/03.06%20-%20CATKEYS%20BUILDS/default-banner.png';
  String userName = '-';
  String userHandle = '-';
  String userFollowers = '-';
  String userFollowing = '-';
  String userNotes = '-';
  String userDescription = '-';
  String userStatus = '-';
  bool userNotificationStatus = false;
  int _selectedChip = 1;
  int posts = 250;
  final TextEditingController _noteController = TextEditingController();

  fetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      url = prefs.getString('catkeys_url') ?? '';
      token = prefs.getString('catkeys_token') ?? '';
      posts = prefs.getInt('catkeys_posts_shows') ?? 250;
    });
    if (url.isNotEmpty && token.isNotEmpty) {
      client = Misskey(
        host: url,
        token: token,
      );
      lookupAccount();
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  lookupAccount() async {
    final res = await client.i.i();
    setState(() {
      profilePicture = res.avatarUrl.toString();
      profileBanner = res.bannerUrl.toString();
      userName = res.name.toString();
      userHandle = res.username.toString();
      userFollowers = res.followersCount.toString();
      userFollowing = res.followingCount.toString();
      userNotes = res.notesCount.toString();
      userDescription = res.description.toString();
      userStatus = res.onlineStatus.toString();
      userNotificationStatus = res.hasUnreadNotification;
    });
  }

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

  createNote() async {
    String content = _noteController.text;
    try {
      await client.notes.create(
        NotesCreateRequest(
          text: content,
          visibility: _selectedChip == 1
              ? NoteVisibility.public
              : _selectedChip == 2
                  ? NoteVisibility.home
                  : _selectedChip == 3
                      ? NoteVisibility.followers
                      : null,
        ),
      );
    } catch (e) {
      print('Error creating note: $e');
    }
    _noteController.text = '';
    _selectedChip = 0;
  }

  repostNote(id) {
    try {
      client.notes.renotes(
        NotesRenoteRequest(
          noteId: id,
        ),
      );
      Fluttertoast.showToast(
        msg: 'Note renoted successfully!',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        textColor: Theme.of(context).colorScheme.primaryContainer,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'There was an error while renoting!',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        backgroundColor: Theme.of(context).colorScheme.onErrorContainer,
        textColor: Theme.of(context).colorScheme.error,
      );
    }
  }

  deleteNote(id) {
    try {
      client.notes.delete(
        NotesDeleteRequest(
          noteId: id,
        ),
      );
      Fluttertoast.showToast(
        msg: 'Note deleted successfully!',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        textColor: Theme.of(context).colorScheme.primaryContainer,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'There was an error while deleting the note!',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        backgroundColor: Theme.of(context).colorScheme.onErrorContainer,
        textColor: Theme.of(context).colorScheme.error,
      );
    }
  }

  Future<List<Note>> fetchNotes() async {
    try {
      final response = await client.notes.homeTimeline(
        NotesTimelineRequest(
          limit: posts,
          includeLocalRenotes: false,
          includeMyRenotes: false,
        ),
      );
      return response.toList();
    } catch (e) {
      return []; // Return an empty list on error
    }
  }

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

  refreshNotesD() {
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        currentPageIndex = 1;
        currentPageIndex = 0;
      });
    });
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

  navSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage(title: 'Settings')),
    );
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
                    value: 'Refresh Notes',
                    child: Row(
                      children: [
                        Icon(Icons.refresh_rounded),
                        SizedBox(width: 10),
                        Text('Refresh Notes'),
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
              onSelected: (value) async {
                if (value == 'Settings') {
                  vibrate();
                  navSettings();
                } else if (value == 'Refresh Notes') {
                  vibrateSel();
                  refreshNotesD();
                } else if (value == 'Source Code') {
                  const url = 'https://github.com/french-femboi/Catkeys';
                  if (await canLaunch(url)) {
                    await launch(url);
                  } else {
                    Fluttertoast.showToast(
                      msg: 'There while launching a browser!',
                      toastLength: Toast.LENGTH_LONG,
                      gravity: ToastGravity.TOP,
                      backgroundColor:
                          Theme.of(context).colorScheme.onErrorContainer,
                      textColor: Theme.of(context).colorScheme.error,
                    );
                  }
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
        body: Center(
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.start, // Align text to the start (left)
            crossAxisAlignment:
                CrossAxisAlignment.start, // Align text to the start (left)
            children: [
              Visibility(
                visible: currentPageIndex == 0,
                maintainState: true,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height -
                            kToolbarHeight - // Subtract the app bar height
                            kBottomNavigationBarHeight -
                            63, // Subtract the bottom nav bar height
                        child: FutureBuilder<List<Note>>(
                          future: fetchNotes(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Center(
                                  child: Text('Error: ${snapshot.error}'));
                            } else if (!snapshot.hasData ||
                                snapshot.data!.isEmpty) {
                              return const Center(
                                  child: Text('No data available'));
                            }
                            return ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: snapshot.data!.length,
                              itemBuilder: (context, index) {
                                final note = snapshot.data![index];
                                return Column(
                                  children: [
                                    ListTile(
                                      title: Text(
                                        note.user.name ?? 'Unknown user',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                      
                                      subtitle: 
                                      Text(
                                        note.text ?? note.renote?.text ?? 'No content available',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondary, // Change the color to red
                                        ),
                                      ),
                                      leading: CircleAvatar(
                                        backgroundImage: NetworkImage(
                                            note.user.avatarUrl.toString()),
                                      ),
                                        
                                    ),
                                    Row(
                                      children: [
                                        if (note.renoteId == null)
                                        IconButton(
                                          icon: Icon(
                                            Icons.repeat_rounded,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondary, // Change the color to red
                                          ),
                                          onPressed: () {
                                            vibrateSel();
                                            repostNote(note.id);
                                          },
                                        ),
                                        if (note.renoteId == null)
                                        Text(
                                          '${note.renoteCount}',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .secondary),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.open_in_browser_rounded,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondary, // Change the color to red
                                          ),
                                          onPressed: () async {
                                            vibrateSel();
                                            openLink(
                                                'https://$url/notes/${note.id}');
                                          },
                                        ),
                                        if (note.user.username == userHandle)
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete_rounded,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .secondary, // Change the color to red
                                            ),
                                            onPressed: () {
                                              vibrateSel();
                                              showDialog(
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  return AlertDialog(
                                                    title: const Text(
                                                        'Deleting Note'),
                                                    content: const Text(
                                                        "Are you sure you want to delete this note? This action can't be undone."),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.of(context)
                                                              .pop();
                                                          vibrateSel();
                                                        },
                                                        child: const Text(
                                                            'Cancel'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          deleteNote(note.id);
                                                          vibrateSel();
                                                          Navigator.of(context)
                                                              .pop();
                                                          refreshNotesD();
                                                        },
                                                        child: const Text(
                                                            'Confirm'),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                        if (note.renoteId != null) ...[
                                            Container(
                                              padding: EdgeInsets.only(right: 3.0), // Add padding only on the right side
                                              decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Theme.of(context).colorScheme.primary,
                                                width: 1.0,
                                              ),
                                              borderRadius: BorderRadius.circular(4.0),
                                              ),
                                              child: Row(
                                              children: [
                                                Icon(
                                                Icons.restart_alt_rounded,
                                                color: Theme.of(context).colorScheme.primary,
                                                ),
                                                Text(
                                                'Renote',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Theme.of(context).colorScheme.primary,
                                                  fontWeight: FontWeight.bold
                                                ),
                                                ),
                                              ],
                                              ),
                                            ),
                                        ],
                                        if (note.visibility == NoteVisibility.followers) ...[
                                            Container(
                                              padding: EdgeInsets.only(right: 3.0), // Add padding only on the right side
                                              decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Theme.of(context).colorScheme.primary,
                                                width: 1.0,
                                              ),
                                              borderRadius: BorderRadius.circular(4.0),
                                              ),
                                              child: Row(
                                              children: [
                                                Icon(
                                                Icons.lock_rounded,
                                                color: Theme.of(context).colorScheme.primary,
                                                ),
                                                Text(
                                                'Followers only',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Theme.of(context).colorScheme.primary,
                                                  fontWeight: FontWeight.bold
                                                ),
                                                ),
                                              ],
                                              ),
                                            ),
                                        ],
                                      ],
                                    ),
                                    const Divider(),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Visibility(
                visible: currentPageIndex == 1,
                maintainState: true,
                child: Column(
                  mainAxisSize: MainAxisSize
                      .min, // This ensures the Column only takes the space it needs
                  children: [
                    Flexible(
                      // Use Flexible instead of Expanded
                      fit: FlexFit
                          .loose, // Allows children to shrink-wrap rather than expanding infinitely
                      child: FutureBuilder<List<Note>>(
                        future: fetchNotes(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(
                                child: Text('Error: ${snapshot.error}'));
                          } else if (!snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return const Center(
                                child: Text('No data available'));
                          }
                          return ListView.builder(
                            shrinkWrap:
                                true, // Add this to allow ListView to size itself properly
                            physics:
                                const NeverScrollableScrollPhysics(), // Prevent ListView from being scrollable if nested
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              final note = snapshot.data![index];
                              return Column(
                                children: [
                                  ListTile(
                                    title:
                                        Text(note.user.name ?? 'Unknown user'),
                                    subtitle: Text(note.text ?? 'No text'),
                                    leading: CircleAvatar(
                                      backgroundImage: NetworkImage(
                                          (note.user.avatarUrl).toString()),
                                    ),
                                  ),
                                  const Divider(), // Add a divider at the bottom
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Visibility(
                visible: currentPageIndex == 2,
                maintainState: true,
                child: const Expanded(
                  child: Text("meow THREE :3"),
                ),
              ),
              Visibility(
                visible: currentPageIndex == 3,
                maintainState: true,
                child: Column(
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
                              '@$userHandle - $url',
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
                            Text(
                              userDescription,
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Divider(),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {
                                vibrateSel();
                                openLink('https://$url/@$userHandle');
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
              ),
            ],
          ),
        ),
        floatingActionButton: currentPageIndex == 0
            ? FloatingActionButton(
                onPressed: () {
                  vibrateSel();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    enableDrag: false, // Disable dragging to dismiss
                    isDismissible:
                        false, // Disable dismissing by clicking outside
                    builder: (BuildContext context) {
                      return StatefulBuilder(
                        builder:
                            (BuildContext context, StateSetter setModalState) {
                          return SingleChildScrollView(
                            child: Container(
                              padding: EdgeInsets.only(
                                bottom:
                                    MediaQuery.of(context).viewInsets.bottom,
                                left: 16,
                                right: 16,
                                top: 16,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Create a note',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Your note will be published as @$userHandle',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextField(
                                    decoration: const InputDecoration(
                                      labelText: 'Note',
                                      border: OutlineInputBorder(),
                                    ),
                                    maxLines: null,
                                    controller: _noteController,
                                    scrollPhysics:
                                        const NeverScrollableScrollPhysics(),
                                  ),
                                  const SizedBox(height: 8),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Note visibility',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Select who can see your note',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                      ),
                                    ),
                                  ),
                                  if (_selectedChip == 0)
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Please select at least one option',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error,
                                        ),
                                      ),
                                    ),
                                  Row(
                                    children: [
                                      ChoiceChip(
                                        label: const Text('Public'),
                                        selected: _selectedChip == 1,
                                        onSelected: (bool selected) {
                                          vibrateSel();
                                          setModalState(() {
                                            _selectedChip = selected ? 1 : 0;
                                          });
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      ChoiceChip(
                                        label: const Text('Home'),
                                        selected: _selectedChip == 2,
                                        onSelected: (bool selected) {
                                          vibrateSel();
                                          setModalState(() {
                                            _selectedChip = selected ? 2 : 0;
                                          });
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      ChoiceChip(
                                        label: const Text('Followers'),
                                        selected: _selectedChip == 3,
                                        onSelected: (bool selected) {
                                          vibrateSel();
                                          setModalState(() {
                                            _selectedChip = selected ? 3 : 0;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          vibrateSel();
                                          Navigator.of(context).pop();
                                          _noteController.text = '';
                                          _selectedChip = 1;
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          vibrateSel();
                                          createNote();
                                          Navigator.of(context).pop();

                                          Fluttertoast.showToast(
                                            msg: 'Note posted successfully!',
                                            toastLength: Toast.LENGTH_LONG,
                                            gravity: ToastGravity.TOP,
                                            backgroundColor: Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer,
                                            textColor: Theme.of(context)
                                                .colorScheme
                                                .primaryContainer,
                                          );

                                          refreshNotesD();
                                        },
                                        child: const Text('Post'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
                backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                child: const Icon(
                    Icons.edit_rounded), // Customize the background color here
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
                if (currentPageIndex == 3) {
                  lookupAccount();
                }
              });
            },
            destinations: <Widget>[
              const NavigationDestination(
                icon: Icon(Icons.home_rounded),
                label: 'Home',
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
                  backgroundImage: CachedNetworkImageProvider(profilePicture),
                  radius: 16, // Adjust the radius to make the image smaller
                ),
                icon: CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(profilePicture),
                  radius: 16, // Adjust the radius to make the image smaller
                ),
                label: userName,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
