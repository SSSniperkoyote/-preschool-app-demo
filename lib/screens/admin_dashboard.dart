import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_student_screen.dart';
import 'assign_teacher_screen.dart';
import 'announcements_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _totalStudents = 0;
  int _totalTeachers = 0;
  int _totalClasses = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;

      // Check if user is authenticated
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Load students with null safety
      final studentsResponse = await supabase
          .from('students')
          .select('id')
          .count(CountOption.exact);

      // Load teachers with proper filtering
      final teachersResponse = await supabase
          .from('users')
          .select('id')
          .eq('role', 'teacher')
          .count(CountOption.exact);

      // Load unique classes - using distinct properly
      final classesResponse = await supabase
          .from('students')
          .select('class_name')
          .not('class_name', 'is', null);

      if (!mounted) return;

      // Extract unique class names
      final classNames = <String>{};
      for (final item in classesResponse) {
        final className = item['class_name'] as String?;
        if (className != null && className.isNotEmpty) {
          classNames.add(className);
        }
      }

      setState(() {
        _totalStudents = studentsResponse.count ?? 0;
        _totalTeachers = teachersResponse.count ?? 0;
        _totalClasses = classNames.length;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading stats: $e');
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Failed to load dashboard data';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSignOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      debugPrint('Error signing out: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error signing out')),
      );
    }
  }

  void _navigateToScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  Widget _buildStatsCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(
                count.toString(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManagementCard({
    required String title,
    required String buttonText,
    required IconData buttonIcon,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(buttonIcon),
              label: Text(buttonText),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.announcement),
            tooltip: 'Announcements',
            onPressed: () => _navigateToScreen(const AnnouncementsScreen() as Widget),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: _handleSignOut,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadStats,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome, Admin',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Management Sections
              _buildManagementCard(
                title: 'Student Management',
                buttonText: 'Add Student',
                buttonIcon: Icons.add,
                onPressed: () => _navigateToScreen(AddStudentScreen()),
              ),
              const SizedBox(height: 16),

              _buildManagementCard(
                title: 'Teacher Assignment',
                buttonText: 'Assign Teacher to Student',
                buttonIcon: Icons.assignment_ind,
                onPressed: () => _navigateToScreen(AssignTeacherScreen()),
              ),
              const SizedBox(height: 16),

              _buildManagementCard(
                title: 'User Management',
                buttonText: 'View All Users',
                buttonIcon: Icons.people,
                onPressed: () {
                  // TODO: Implement view all users
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Feature coming soon'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // System Overview
              const Text(
                'System Overview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  _buildStatsCard(
                    title: 'Students',
                    count: _totalStudents,
                    icon: Icons.school,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 16),
                  _buildStatsCard(
                    title: 'Teachers',
                    count: _totalTeachers,
                    icon: Icons.person,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 16),
                  _buildStatsCard(
                    title: 'Classes',
                    count: _totalClasses,
                    icon: Icons.class_,
                    color: Colors.orange,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnnouncementsScreen {
  const AnnouncementsScreen();
}