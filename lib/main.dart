import 'package:collabwrite/data/models/story_model.dart';
import 'package:collabwrite/services/auth_service.dart';
import 'package:collabwrite/viewmodel/create_viewmodel.dart';
import 'package:collabwrite/viewmodel/library_viewmodel.dart';
import 'package:collabwrite/viewmodel/profile_viewmodel.dart';
import 'package:collabwrite/views/collab/collaboration_screen.dart';
import 'package:collabwrite/views/create/create_screen.dart';
import 'package:collabwrite/views/home/home_screen.dart';
import 'package:collabwrite/views/library/library_screen.dart';
import 'package:collabwrite/views/login/login_screen.dart';
import 'package:collabwrite/views/profile/profile_screen.dart';
import 'package:collabwrite/views/splash/splash_screen.dart';
import 'package:collabwrite/views/signup/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LibraryViewModel()),
        ChangeNotifierProvider(create: (_) => CreateViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CollabWrite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => SplashScreen(
              onInitializationComplete: () async {
                await Future.delayed(const Duration(seconds: 1));
              },
            ),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(),
        '/library': (context) => const LibraryScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/create': (context) {
          final Story? draftStory =
              ModalRoute.of(context)?.settings.arguments as Story?;
          print(
              "Navigating to /create with draftStory: ${draftStory != null ? 'exists' : 'none'}");
          return ChangeNotifierProvider<CreateViewModel>(
            create: (_) {
              final viewModel = CreateViewModel()
                ..initialize(draftStory: draftStory);
              print("Created CreateViewModel");
              return viewModel;
            },
            child: CreateScreen(draftStory: draftStory),
          );
        },
        '/collaboration': (context) {
          final Story story =
              ModalRoute.of(context)!.settings.arguments as Story;
          return CollaborationScreen(story: story);
        }, // Add this route
      },
    );
  }
}
