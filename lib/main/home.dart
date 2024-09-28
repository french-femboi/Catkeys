// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:catkeys/internal/video-player.dart';
import 'package:catkeys/main/settings.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:misskey_dart/misskey_dart.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../pre/setup.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarIconBrightness: Brightness.light, // Light icons on dark background
    statusBarColor: Colors.transparent, // Make status bar transparent
    systemNavigationBarColor:
        Colors.transparent, // Make navigation bar transparent
    systemNavigationBarIconBrightness:
        Brightness.light, // Light icons on navigation bar
  ));
  runApp(const Home());
}

class Home extends StatelessWidget {
  const Home({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp(
          title: 'CatKeys',
          themeMode: ThemeMode.dark,
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkDynamic?.harmonized() ??
                ColorScheme.fromSeed(
                    seedColor: Colors.purple, brightness: Brightness.dark),
            fontFamily: 'Inter',
          ),
          home: const HomePage(title: 'CatKeys'),
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class DriveItem {
  final String id;
  final String name;
  final int size;

  DriveItem({
    required this.id,
    required this.name,
    required this.size,
  });

  factory DriveItem.fromJson(Map<String, dynamic> json) {
    return DriveItem(
      id: json['id'],
      name: json['name'],
      size: json['size'],
    );
  }
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late Misskey client;
  String url = '';
  String token = '';
  int currentPageIndex = 0;
  String profilePicture = '';
  String profileBanner = '';
  String userName = '-';
  String userHandle = '-';
  String userFollowers = '-';
  String userFollowing = '-';
  String userNotes = '-';
  String userDescription = '-';
  String userJoined = '-';
  String userBirthday = '-';
  String userLocation = '-';
  String userLang = '-';
  String userStatus = '-';
  String userID = '';

  Map<String, String> _customEmojis = {};

  bool showProfile = false;

  String ext_profilePicture = '';
  String ext_userID = '';
  String ext_instance = '';
  int _selectedChip = 1;
  int posts = 250;
  int tabIndex = 0;
  final TextEditingController _noteController = TextEditingController();
  late final TabController tabs1 = TabController(length: 3, vsync: this);

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
      _loadEmojis();
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData();

    tabs1.addListener(() {
      setState(() {
        tabIndex = tabs1.index;
      });
      vibrateSelection();
    });

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarIconBrightness:
          Brightness.light, // Light icons on dark background
      statusBarColor: Colors.transparent, // Make status bar transparent
      systemNavigationBarColor:
          Colors.transparent, // Make navigation bar transparent
      systemNavigationBarIconBrightness:
          Brightness.light, // Light icons on navigation bar
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<Map<String, String>> fetchCustomEmojis() async {
    // Assuming you have a method to make a request to the Misskey API.
    final response = await client.emojis(); // Fetches custom emojis
    Map<String, String> emojiMap = {};

    for (var emoji in response.emojis) {
      // Assuming 'emojis' is the iterable property
      emojiMap[emoji.name] =
          (emoji.url).toString(); // Map emoji name to its URL
    }

    return emojiMap;
  }

  Future<void> _loadEmojis() async {
    Map<String, String> emojis =
        await fetchCustomEmojis(); // Fetch the emojis from Misskey
    setState(() {
      _customEmojis = emojis; // Update the state with the fetched emojis
    });
  }

  String _replaceEmojis(String text) {
    String modifiedText = text;
    _customEmojis.forEach((emojiCode, emojiUrl) {
      final emojiMarkdown = '![]($emojiUrl)';
      modifiedText = modifiedText.replaceAll(':$emojiCode:', emojiMarkdown);
    });
    return modifiedText;
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
      userID = res.id.toString();
      userJoined =
          (DateFormat('dd/MM/yyyy – kk:mm').format(res.createdAt)).toString();
      userBirthday = res.birthday != null
          ? (DateFormat('dd/MM/yyyy – kk:mm').format(res.birthday!)).toString()
          : '-';
      userLocation = res.location.toString();
      userLang = res.lang.toString();
    });
  }

  openProfile(uID) async {
    try {
      final res = await client.users.show(
        UsersShowRequest(
          userId: uID, // Replace with the actual user ID
        ),
      );
      setState(() {
        ext_profilePicture = res.avatarUrl.toString();
        ext_instance = res.host.toString();
        profileBanner = res.bannerUrl.toString();
        userName = res.name.toString();
        userHandle = res.username.toString();
        userFollowers = res.followersCount.toString();
        userFollowing = res.followingCount.toString();
        userNotes = res.notesCount.toString();
        userDescription = res.description.toString();
        userStatus = res.onlineStatus.toString();
        ext_userID = res.id.toString();
        userJoined =
            (DateFormat('dd/MM/yyyy – kk:mm').format(res.createdAt)).toString();
        userBirthday = res.birthday != null
            ? (DateFormat('dd/MM/yyyy – kk:mm').format(res.birthday!))
                .toString()
            : '-';
        userLocation = res.location.toString();
        userLang = res.lang.toString();
      });
    } catch (e) {
      print('Error: $e'); // Catch and print any errors
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  vibrateSelection() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? status = prefs.getBool('catkeys_haptics');
    if (status == true) {
      final hasCustomVibrationsSupport =
          await Vibration.hasCustomVibrationsSupport();
      if (hasCustomVibrationsSupport != null && hasCustomVibrationsSupport) {
        Vibration.vibrate(duration: 50);
      } else {
        Vibration.vibrate();
        await Future.delayed(const Duration(milliseconds: 50));
        Vibration.vibrate();
      }
    }
  }

  vibrateError() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? status = prefs.getBool('catkeys_haptics');
    if (status == true) {
      final hasCustomVibrationsSupport =
          await Vibration.hasCustomVibrationsSupport();
      if (hasCustomVibrationsSupport != null && hasCustomVibrationsSupport) {
        Vibration.vibrate(duration: 200);
      } else {
        Vibration.vibrate();
        await Future.delayed(const Duration(milliseconds: 200));
        Vibration.vibrate();
      }
    }
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
    } catch (e) {}
    _noteController.text = '';
    _selectedChip = 0;
  }

  repostNote(id) async {
    try {
      await client.notes.create(
        NotesCreateRequest(
          renoteId:
              id, // Set the renoteId to the ID of the note you want to renote
        ),
      );
      Fluttertoast.showToast(
        msg: 'Note renoted successfully!',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        textColor: Theme.of(context).colorScheme.onPrimaryContainer,
      );
      refreshNotesD();
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
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        textColor: Theme.of(context).colorScheme.onPrimaryContainer,
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

  Future<List<DriveFile>> fetchDriveItems() async {
    try {
      final response = await client.drive.files.files(
        DriveFilesRequest(
          limit: posts,
        ),
      );
      if (kDebugMode) {
        print('------------------ DRIVE DEBUG ------------------');
        print(response);
        print('------------------ DRIVE DEBUG ------------------');
      }
      return response.toList();
    } catch (e) {
      print('Error: $e');
      return []; // Return an empty list on error
    }
  }

  Future<List<Note>> fetchNotesHome() async {
    try {
      final response = await client.notes.homeTimeline(
        NotesTimelineRequest(
          limit: posts,
        ),
      );
      if (kDebugMode) {
        print('------------------ HOME DEBUG ------------------');
        print(response);
        print('------------------ HOME DEBUG ------------------');
      }
      return response.toList();
    } catch (e) {
      return []; // Return an empty list on error
    }
  }

  Future<List<Note>> fetchNotesLocal() async {
    try {
      final response = await client.notes.localTimeline(
        NotesLocalTimelineRequest(
          limit: posts,
        ),
      );
      if (kDebugMode) {
        print('------------------ LOCAL DEBUG ------------------');
        print(response);
        print('------------------ LOCAL DEBUG ------------------');
      }
      return response.toList();
    } catch (e) {
      return []; // Return an empty list on error
    }
  }

  Future<List<Note>> fetchNotesGlobal() async {
    try {
      final response = await client.notes.globalTimeline(
        NotesGlobalTimelineRequest(
          limit: posts,
        ),
      );
      if (kDebugMode) {
        print('------------------ GLOBAL DEBUG ------------------');
        print(response);
        print('------------------ GLOBAL DEBUG ------------------');
      }
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
            builder: (context) => const SetupPage(title: 'CatKeys setup')),
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
      MaterialPageRoute(
          builder: (context) => const SettingsPage(title: 'Settings')),
    );
  }

  navProfile() {
    currentPageIndex = 3;
  }

  Future<bool> isVideoFile(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      final contentType = response.headers['content-type'];
      return contentType != null && contentType.startsWith('video/');
    } catch (e) {
      // Handle error (e.g., log it)
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarIconBrightness:
          Brightness.light, // Light icons on dark background
      statusBarColor: Colors.transparent, // Make status bar transparent
      systemNavigationBarColor:
          Colors.transparent, // Make navigation bar transparent
      systemNavigationBarIconBrightness:
          Brightness.light, // Light icons on navigation bar
    ));
    return WillPopScope(
      onWillPop: () {
        return Future.value(false);
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarIconBrightness:
                Brightness.light, // Light icons on dark background
            statusBarColor: Colors.transparent, // Make status bar transparent
          ),
          backgroundColor:
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
                  vibrateSelection();
                  navSettings();
                } else if (value == 'Refresh Notes') {
                  vibrateSelection();
                  refreshNotesD();
                } else if (value == 'Source Code') {
                  vibrateSelection();
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
                  vibrateError();
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
                              vibrateSelection();
                            },
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              clearData();
                              vibrateSelection();
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
                      DefaultTabController(
                          length: 3,
                          child: Container(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(
                                    0.1), // Change this to your desired background color
                            child: TabBar(
                              controller: tabs1,
                              tabs: const [
                                Tab(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.home_rounded),
                                      SizedBox(width: 8),
                                      Text('Home'),
                                    ],
                                  ),
                                ),
                                Tab(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.dns_rounded),
                                      SizedBox(width: 8),
                                      Text('Local'),
                                    ],
                                  ),
                                ),
                                Tab(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.public_rounded),
                                      SizedBox(width: 8),
                                      Text('Global'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )),
                      SizedBox(
                        height: MediaQuery.of(context).size.height -
                            kToolbarHeight - // Subtract the app bar height
                            kBottomNavigationBarHeight -
                            110, // Subtract the bottom nav bar height
                        // Tab 1 content
                        child: FutureBuilder<List<Note>>(
                          future: tabIndex == 0
                              ? fetchNotesHome()
                              : tabIndex == 1
                                  ? fetchNotesLocal()
                                  : tabIndex == 2
                                      ? fetchNotesGlobal()
                                      : Future.value([]),
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
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (note.text != null ||
                                              note.renote?.text != null)
                                            MarkdownBody(
                                              data: _replaceEmojis(
                                                      note.text ?? '') ??
                                                  _replaceEmojis(
                                                      note.renote?.text ??
                                                          '') ??
                                                  'No content available',
                                              styleSheet: MarkdownStyleSheet(
                                                p: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                              onTapLink: (text, url, title) {
                                                if (url != null) {
                                                  vibrateSelection();
                                                  openLink(url);
                                                }
                                              },
                                              imageBuilder: (uri, title, alt) {
                                                // Here we control the size of the custom emojis
                                                return Image.network(
                                                  uri.toString(),
                                                  width:
                                                      20, // Adjust the width of the emoji
                                                  height:
                                                      20, // Adjust the height of the emoji
                                                  fit: BoxFit.contain,
                                                );
                                              },
                                            ),
                                          if (note.files != null &&
                                              note.files!.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 8.0),
                                              child: Wrap(
                                                spacing: 8.0,
                                                runSpacing: 8.0,
                                                children:
                                                    note.files!.map((file) {
                                                  return FutureBuilder<bool>(
                                                    future: isVideoFile(file
                                                        .url), // Check if it's a video
                                                    builder:
                                                        (context, snapshot) {
                                                      if (snapshot
                                                              .connectionState ==
                                                          ConnectionState
                                                              .waiting) {
                                                        return const CircularProgressIndicator();
                                                      } else if (snapshot
                                                          .hasError) {
                                                        return const Icon(
                                                            Icons.error);
                                                      } else if (snapshot
                                                              .hasData &&
                                                          snapshot.data!) {
                                                        // It's a video, display video-related UI
                                                        return GestureDetector(
                                                          onTap: () {
                                                            vibrateSelection(); // Trigger vibration on video tap
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder: (context) =>
                                                                    VideoPlayerPage(
                                                                        videoUrl:
                                                                            file.url),
                                                              ),
                                                            );
                                                          },
                                                          child: Stack(
                                                            alignment: Alignment
                                                                .center,
                                                            children: [
                                                              Container(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .only(
                                                                        right:
                                                                            3.0),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  border: Border
                                                                      .all(
                                                                    color: Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .primary,
                                                                    width: 1.0,
                                                                  ),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              4.0),
                                                                ),
                                                                child: Row(
                                                                  children: [
                                                                    Icon(
                                                                      Icons
                                                                          .movie_rounded,
                                                                      color: Theme.of(
                                                                              context)
                                                                          .colorScheme
                                                                          .primary,
                                                                    ),
                                                                    Text(
                                                                      'Click to open attached video',
                                                                      style:
                                                                          TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        color: Theme.of(context)
                                                                            .colorScheme
                                                                            .primary,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      } else {
                                                        // It's an image, display the image and open lightbox on tap
                                                        return GestureDetector(
                                                          onTap: () {
                                                            vibrateSelection(); // Trigger vibration on image tap

                                                            // Open lightbox for image
                                                            showDialog(
                                                              context: context,
                                                              builder:
                                                                  (BuildContext
                                                                      context) {
                                                                return Material(
                                                                  color: Colors
                                                                      .transparent,
                                                                  child: Stack(
                                                                    children: [
                                                                      BackdropFilter(
                                                                        filter: ImageFilter.blur(
                                                                            sigmaX:
                                                                                10,
                                                                            sigmaY:
                                                                                10),
                                                                        child:
                                                                            Container(
                                                                          width: MediaQuery.of(context)
                                                                              .size
                                                                              .width,
                                                                          height: MediaQuery.of(context)
                                                                              .size
                                                                              .height,
                                                                        ),
                                                                      ),
                                                                      // Full-screen image
                                                                      InteractiveViewer(
                                                                        minScale:
                                                                            0.8,
                                                                        maxScale:
                                                                            4.0,
                                                                        child:
                                                                            Center(
                                                                          child:
                                                                              Image.network(
                                                                            file.url,
                                                                            fit:
                                                                                BoxFit.contain,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      // Close button
                                                                      Positioned(
                                                                        top: 16,
                                                                        left:
                                                                            16,
                                                                        child:
                                                                            IconButton(
                                                                          icon: const Icon(
                                                                              Icons.close,
                                                                              color: Colors.white),
                                                                          onPressed:
                                                                              () {
                                                                            vibrateSelection();
                                                                            Navigator.of(context).pop();
                                                                          },
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                );
                                                              },
                                                            );
                                                          },
                                                          child: Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              border:
                                                                  Border.all(
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .primary,
                                                                width: 1.0,
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8.0),
                                                            ),
                                                            child: ClipRRect(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          7.0),
                                                              child:
                                                                  Image.network(
                                                                file.url,
                                                                fit: BoxFit
                                                                    .cover,
                                                                height: 150,
                                                                width: 150,
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    },
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                        ],
                                      ),
                                      leading: GestureDetector(
                                        onTap: () {
                                          vibrateSelection();
                                          openProfile(note.userId);
                                          navProfile();
                                        },
                                        child: CircleAvatar(
                                          backgroundImage: NetworkImage(
                                              note.user.avatarUrl.toString()),
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.repeat_rounded,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondary, // Change the color to red
                                          ),
                                          onPressed: () {
                                            vibrateSelection();
                                            repostNote(note.id);
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.open_in_browser_rounded,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondary, // Change the color to red
                                          ),
                                          onPressed: () async {
                                            vibrateSelection();
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
                                              vibrateSelection();
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
                                                          vibrateSelection();
                                                        },
                                                        child: const Text(
                                                            'Cancel'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          deleteNote(note.id);
                                                          vibrateSelection();
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
                                            padding: const EdgeInsets.only(
                                                right:
                                                    3.0), // Add padding only on the right side
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4.0),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.restart_alt_rounded,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                ),
                                                Text(
                                                  'Renote',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        if (note.visibility ==
                                            NoteVisibility.followers) ...[
                                          Container(
                                            padding: const EdgeInsets.only(
                                                right:
                                                    3.0), // Add padding only on the right side
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4.0),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.lock_rounded,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                ),
                                                Text(
                                                  'Followers only',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                      fontWeight:
                                                          FontWeight.bold),
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
                child: SizedBox(
                  height: MediaQuery.of(context).size.height -
                      kToolbarHeight - // Subtract the app bar height
                      kBottomNavigationBarHeight -
                      65, // Subtract the bottom nav bar height
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment
                              .start, // Align children to the top
                          children: [
                            Icon(
                              Icons.info_rounded,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                "This page will display several different account statistics such as drive usage, followers, following, and more. This page is still under development.",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.start,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: currentPageIndex == 2,
                maintainState: true,
                child: SizedBox(
                  height: MediaQuery.of(context).size.height -
                      kToolbarHeight - // Subtract the app bar height
                      kBottomNavigationBarHeight -
                      65, // Subtract the bottom nav bar height
                  child: FutureBuilder<List<DriveFile>>(
                    future: fetchDriveItems(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                            child: Text('No drive items available.'));
                      } else {
                        final driveItems = snapshot.data!;
                        return ListView.builder(
                          shrinkWrap:
                              true, // Enable shrinkWrap to prevent unbounded height
                          itemCount: driveItems.length,
                          itemBuilder: (context, index) {
                            final driveItem = driveItems[index];
                            return Column(
                              children: [
                                ListTile(
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: driveItem.thumbnailUrl != null &&
                                            driveItem.thumbnailUrl!.isNotEmpty
                                        ? Image.network(
                                            driveItem.thumbnailUrl!,
                                            fit: BoxFit.cover,
                                            width: 50,
                                            height: 50,
                                          )
                                        : Icon(
                                            Icons.insert_drive_file_rounded,
                                            size: 50,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                  ),
                                  title: Text(driveItem.name),
                                  subtitle: Text(
                                      '${(driveItem.size / (1024 * 1024)).toStringAsFixed(2)} MB - ${DateFormat('dd/MM/yyyy – kk:mm').format(driveItem.createdAt)}'),
                                  onTap: () {
                                    vibrateSelection();
                                    openLink(driveItem.url);
                                  },
                                ),
                                const Divider(),
                              ],
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
              ),
              Visibility(
                visible: currentPageIndex == 3 || currentPageIndex == 4,
                maintainState: true,
                child: SizedBox(
                  height: MediaQuery.of(context).size.height -
                      kToolbarHeight - // Subtract the app bar height
                      kBottomNavigationBarHeight -
                      65,
                  child: SingleChildScrollView(
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
                                    image: CachedNetworkImageProvider(
                                        profileBanner),
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
                                                  ext_profilePicture),
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
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '@$userHandle - ${ext_instance == "null" ? url : ext_instance}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Status: ${userStatus == "OnlineStatus.online" ? "Online" : userStatus == "OnlineStatus.offline" ? "Offline" : userStatus == "OnlineStatus.active" ? "Active" : userStatus == "OnlineStatus.unknown" ? "Unknown" : userStatus}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
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
                                            style: const TextStyle(
                                              color: Colors.white,
                                            )), // Replace '200' with the actual value
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
                                            style: const TextStyle(
                                              color: Colors.white,
                                            )), // Replace '200' with the actual value
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
                                            style: const TextStyle(
                                              color: Colors.white,
                                            )), // Replace '100' with the actual value
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                const Divider(),
                                const SizedBox(height: 10),
                                Text("Information",
                                    style: const TextStyle(
                                      color: Colors.white,
                                    )),
                                if (userJoined != "-" &&
                                    userJoined != "null") //
                                  MarkdownBody(
                                    data:
                                        '**Joined:** $userJoined', // Markdown text
                                    styleSheet: MarkdownStyleSheet(
                                      p: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white, // Text style
                                      ),
                                    ),
                                  ),
                                if (userBirthday != "-" &&
                                    userBirthday != "null")
                                  MarkdownBody(
                                    data:
                                        '**Birthday:** $userBirthday', // Markdown text
                                    styleSheet: MarkdownStyleSheet(
                                      p: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white, // Text style
                                      ),
                                    ),
                                  ),
                                if (userLocation != "-" &&
                                    userLocation != "null")
                                  MarkdownBody(
                                    data:
                                        '**Location:** $userLocation', // Markdown text
                                    styleSheet: MarkdownStyleSheet(
                                      p: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white, // Text style
                                      ),
                                    ),
                                  ),
                                if (userLang != "-" && userLang != "null")
                                  MarkdownBody(
                                    data:
                                        '**Language:** $userLang', // Markdown text
                                    styleSheet: MarkdownStyleSheet(
                                      p: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white, // Text style
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 5),
                                const Divider(),
                                const SizedBox(height: 10),
                                MarkdownBody(
                                  data: userDescription ??
                                      'No description available', // Markdown text
                                  styleSheet: MarkdownStyleSheet(
                                    p: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white, // Text style
                                    ),
                                  ),
                                  onTapLink: (text, url, title) {
                                    if (url != null) {
                                      openLink(
                                          url); // Open the link when tapped
                                    }
                                  },
                                ),
                                const SizedBox(height: 10),
                                const Divider(),
                                const SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: () {
                                    vibrateSelection();
                                    openLink(
                                        'https://$url/@$userHandle${ext_instance != "null" ? "@$ext_instance" : ""}');
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
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    vibrateSelection();
                                    Share.share(
                                        'Check out this user profile: https://$url/@$userHandle');
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
                                          .share_rounded), // Add your desired icon
                                      SizedBox(
                                          width:
                                              8), // Add some spacing between the icon and text
                                      Text(
                                          'Share profile'), // Add your desired text
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                        // Add more profile content here
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: currentPageIndex == 0
            ? FloatingActionButton(
                onPressed: () {
                  vibrateSelection();
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
                                          vibrateSelection();
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
                                          vibrateSelection();
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
                                          vibrateSelection();
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
                                          vibrateSelection();
                                          Navigator.of(context).pop();
                                          _noteController.text = '';
                                          _selectedChip = 1;
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          vibrateSelection();
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
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.3),
                child: const Icon(
                    Icons.edit_rounded), // Customize the background color here
              )
            : null,
        bottomNavigationBar: SizedBox(
          height: 60, // Adjust the height as desired
          child: NavigationBar(
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            backgroundColor:
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
            selectedIndex: currentPageIndex,
            onDestinationSelected: (int index) {
              vibrateSelection();
              setState(() {
                currentPageIndex = index;
                if (currentPageIndex == 3) {
                  lookupAccount();
                  openProfile(userID);
                } else {
                  openProfile(userID);
                }
              });
            },
            destinations: <Widget>[
              const NavigationDestination(
                icon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              const NavigationDestination(
                selectedIcon: Icon(Icons.show_chart_rounded),
                icon: Icon(Icons.show_chart_rounded),
                label: 'Status',
              ),
              const NavigationDestination(
                icon: Icon(Icons.cloud_rounded),
                label: 'Drive',
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
            ].where((destination) => destination != null).toList(),
          ),
        ),
      ),
    );
  }
}
