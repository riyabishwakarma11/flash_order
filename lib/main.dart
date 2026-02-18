import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/app_state.dart';
import 'screens/customer_menu.dart';
import 'screens/admin_shell.dart';

Future<void> main() async {
  // THIS IS THE START BUTTON THE COMPILER IS LOOKING FOR
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, 
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true
      ), 
      home: const EntryScreen()
    );
  }
}

class EntryScreen extends StatelessWidget {
  const EntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
            const Icon(Icons.flash_on, size: 80, color: Colors.orange),
            const Text("FLASH ORDER", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 50),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(220, 55)),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const CustomerMenu())), 
              child: const Text("ORDER FOOD", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 15),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminShell())), 
              child: const Text("ADMIN DASHBOARD", style: TextStyle(color: Colors.blueGrey)),
            ),
          ],
        ),
      ),
    );
  }
}