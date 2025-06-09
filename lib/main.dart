import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/parent_dashboard.dart';
import 'screens/teacher_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtubmxzZW51a2xxbHplcmxqbWRpIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0NjkxMTUyMywiZXhwIjoyMDYyNDg3NTIzfQ.3LiqmBM0RxQWLrOxn2WlvHnwZHvNqxQ5fEkFWBdzGEs',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtubmxzZW51a2xxbHplcmxqbWRpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY5MTE1MjMsImV4cCI6MjA2MjQ4NzUyM30.rFGtd1vVAuR2i59aFGwt54CZFSa3QiE2oDAkYueG-_Q',
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Preschool Management',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      home: LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}