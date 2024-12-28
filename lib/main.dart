import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_app/getauthtokenandkey.dart';
import 'package:test_app/parent_pages/ai_chatbot.dart';
import 'package:test_app/widgets/parent_provider.dart';
import 'package:test_app/parent_pages/stats_page.dart';
import 'firebase_options.dart';
import 'package:test_app/parent_pages/child_management_page.dart';
import 'child_pages/music_page.dart';
import 'widgets/child_provider.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/bottom_nav_bar.dart';
import 'child_pages/home_page.dart';
import 'child_pages/settings_page.dart';
import 'parent_pages/parent_login_page.dart';
import 'child_pages/child_login_page.dart';
import 'parent_pages/parent_settings.dart';
import 'child_pages/feelings_page.dart';
import 'child_pages/fidget_spinner_suggestion.dart';
import 'child_pages/suggestions_page.dart';
import 'child_pages/coloring_suggestion.dart';
import 'child_pages/breathing_suggestion.dart';
import 'child_pages/54321_suggestion.dart';
import 'widgets/globals.dart';
import 'cache_utility.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:test_app/getauthtokenandkey.dart'; // Add this line
import 'widgets/theme_provider.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:test_app/auth_logic.dart';

typedef VoidCallBack = void Function();
final GlobalKey<BasePageState> basePageKey1 = GlobalKey<BasePageState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize ThemeProvider with a default theme
  final themeProvider = ThemeProvider(
    ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Color(0xffdde8ff)),
    ),
    'default',
  );

  await themeProvider.loadTheme(); // Load the theme from Firebase

  try {
    // Attempt to initialize Firebase only if no instance exists
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.ios);
    }
  } catch (e) {
    print("Firebase initialization error: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ChildProvider()),
        ChangeNotifierProvider(create: (_) => themeProvider),
        ChangeNotifierProvider(create: (context) => ParentProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<String> _initialRouteFuture;

  @override
  void initState() {
    super.initState();
    _initialRouteFuture = getInitialRoute(context); // Call the method once
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return FutureBuilder<String>(
      future: _initialRouteFuture, // Use the cached future
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator()); // Loading state
        }

        final initialRoute = snapshot.data ?? '/child_login'; // Default route

        return ChangeNotifierProvider(
          create: (context) => MyAppState(),
          child: MaterialApp(
            title: 'Namer App',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.themeData,
            initialRoute: initialRoute,
            routes: {
              '/parent_login': (_) => ParentLoginPage(),
              '/child_login': (_) => ChildLoginPage(),
              '/base': (_) => BasePage(key: basePageKey1),
              '/feelings': (_) => FeelingsPage(),
              '/music': (_) => MusicPage(),
              '/suggestions': (_) => SuggestionsPage(),
              '/fidget': (_) => FidgetSpinnerHome(),
              '/coloring': (_) => ColoringHome(),
              '/breathing': (_) => BreathingHome(),
              '/54321': (_) => FiveCalmDownHome(),
              '/parent_base': (_) => ParentBasePage(),
            },
          ),
        );
      },
    );
  }
}

Future<String> getInitialRoute(BuildContext context) async {
  try {
    final AuthService _auth = AuthService();

    print('Getting initial route');
    final prefs = await SharedPreferences.getInstance();

    // Retrieve login type and username from shared preferences
    final loginType = prefs.getString('loginType');
    final loginUsername = prefs.getString('loginUser');

    if (loginType == 'parent') {
      // Validate Firebase parent authentication
      if (await validateParentLogin()) {
        return '/parent_base'; // Parent Home Page
      } else {
        return '/parent_login'; // Default to parent login
      }
    } else if (loginType == 'child') {
      if (loginUsername != null && await validateChildToken()) {
        // Validate child token and sign in
        await _auth.signInChild(loginUsername!, '', context, alreadyAuth: true);
        print('Valid child token');
        return '/base';
      } else {
        // Remove invalid child token
        prefs.remove('childToken');
        print('Invalid child token');
      }
    }

    // Default to child login if no valid login found
    return '/child_login';
  } catch (e, stackTrace) {
    // Log the error and return default login route
    print('Error in getInitialRoute: $e');
    print('Stack trace: $stackTrace');
    return '/child_login'; // Default to child login
  }
}

Future<bool> validateParentLogin() async {
  // Check if a user is logged in with Firebase
  final user = FirebaseAuth.instance.currentUser;
  return user != null;
}

Future<bool> validateChildToken() async {
  final token = await getChildTokenFromStorage();
  return token != null && await isTokenValid(token);
}

Future<String?> getChildTokenFromStorage() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('childToken');
}

Future<bool> isTokenValid(String token) async {
  try {
    // Decode and check expiration
    return !JwtDecoder.isExpired(token);
  } catch (e) {
    print('Invalid Token: $e');
    return false;
  }
}

class MyAppState extends ChangeNotifier {}

class BasePage extends StatefulWidget {
  const BasePage({Key? key}) : super(key: key);

  @override
  State<BasePage> createState() => BasePageState();
}

class BasePageState extends State<BasePage> {
  int selectedIndex = 0;
  List<dynamic> pathOfBoard = ["buttons"];
  Map<String, List> data = {};
  bool isLoading = true;
  final GlobalKey<HomePageState> homePageKey = GlobalKey<HomePageState>();

  @override
  void initState() {
    super.initState();
    print(
        "BasePage initialized with key: ${widget.key}"); // Confirm key assignment
    // Fetch login child data and set loading state
    fetchLoginChildData(context, false).then((_) {
      setState(() {
        isLoading = false;
      });
    });

    loadJsonData();
  }

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;

      // Call the desired method when index 0 is selected
      if (index == 0) {
        onHomePageVisible();
      }
    });
  }

  /// Method to perform actions when HomePage (case 0) becomes visible
  void onHomePageVisible() {
    if (isLoading) return;
    print("HomePage (case 0) is now visible.");

    final childProvider = Provider.of<ChildProvider>(context, listen: false);
    String? childUsername = childProvider.childData?['username'];
    String? childId = childProvider.childId;
    print('childUsername: $childUsername');

    refreshGridFromLatestBoard(context, childUsername!, childId!, false);
  }

  Future<void> loadJsonData() async {
    final childProvider = Provider.of<ChildProvider>(context, listen: false);
    String? childId = childProvider.childId;

    String? jsonString =
        await Provider.of<ChildProvider>(context, listen: false)
            .fetchJson('board.json', childId!);

    if (jsonString != null) {
      final jsonData = jsonDecode(jsonString);

      setState(() {
        data = Map.from(jsonData);
      });
    }
  }

  void updatePathOfBoard(List<dynamic> newPath) {
    setState(() {
      pathOfBoard = List.from(newPath);
    });
  }

  void goBack() {
    setState(() {
      if (pathOfBoard.length > 1) {
        pathOfBoard.removeLast();
        pathOfBoard.removeLast();

        updatePathOfBoard(pathOfBoard);
      }
    });
  }

  Future<void> modifyData(Map<String, List> newData,
      {bool isUpload = false}) async {
    setState(() {
      data = Map.from(newData);
    });
    String childId =
        Provider.of<ChildProvider>(context, listen: false).childId!;
    await Provider.of<ChildProvider>(context, listen: false)
        .changeGridJson(newData, childId);
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator if data is being fetched
    if (isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text("Please wait, loading data..."),
            ],
          ),
        ),
      );
    }

    // Permission settings from the Provider
    final childPermission =
        Provider.of<ChildProvider>(context, listen: false).childPermission;
    final canUseEmotionHandling = childPermission?.emotionHandling ?? false;
    final canUseAudioPage = childPermission?.audioPage ?? false;

    // Get the appropriate page based on permissions and selectedIndex
    Widget _getPage() {
      switch (selectedIndex) {
        case 0:
          return DataWidget(
            data: data,
            onDataChange: (Map<String, List> newData) async {
              await modifyData(newData); // Fixed to await the async function
            },
            child: PathWidget(
              onPathChange: (newPath) => setState(() {
                pathOfBoard =
                    List.from(newPath); // Preserves original functionality
              }),
              pathOfBoard: pathOfBoard,
              child: HomePage(
                key: homePageKey,
                isLoading: isLoading,
              ),
            ),
          );
        case 1:
          return canUseEmotionHandling ? FeelingsPage() : CustomSettings();
        case 2:
          return canUseAudioPage ? MusicPage() : CustomSettings();
        case 3:
          return CustomSettings();
        default:
          throw UnimplementedError('No widget for $selectedIndex');
      }
    }

    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(child: _getPage()),
          CustomNavigationBar(
            selectedIndex: selectedIndex,
            onItemTapped: onItemTapped,
          ),
        ],
      ),
    );
  }
}

class ParentBasePage extends StatefulWidget {
  const ParentBasePage({super.key});

  @override
  ParentBasePageState createState() => ParentBasePageState();
}

class ParentBasePageState extends State<ParentBasePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    List<Widget> _widgetOptions = <Widget>[
      ChildManagementPage(
        onNavigate: (int index) {
          _onItemTapped(index);
        },
      ),
      StatsPage(),
      ChatPage(),
      ParentSettingsPage(),
    ];

    return Scaffold(
      body: Container(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.people, color: theme.iconTheme.color),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart, color: theme.iconTheme.color),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat, color: theme.iconTheme.color),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings, color: theme.iconTheme.color),
            label: '',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: theme.primaryColorDark,
        unselectedItemColor: theme.primaryColorLight,
        selectedIconTheme: IconThemeData(
          size: 30,
        ),
        unselectedIconTheme: IconThemeData(
          size: 25,
        ),
        onTap: _onItemTapped,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        iconSize: 20,
        selectedFontSize: 0,
        unselectedFontSize: 0,
      ),
    );
  }
}
