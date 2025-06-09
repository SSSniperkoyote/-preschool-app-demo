import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_dashboard.dart' hide AnnouncementsScreen;
import 'attendance_screen.dart';
import 'messages_screen.dart';
import 'announcements_screen.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({Key? key}) : super(key: key);

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  String _teacherName = '';
  int _studentCount = 0;
  List<Map<String, dynamic>> _students = [];
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredStudents = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTeacherData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get teacher info and students concurrently
      final results = await Future.wait([
        supabase
            .from('users')
            .select('full_name')
            .eq('id', user.id)
            .single(),
        supabase
            .from('students')
            .select('*')
            .eq('teacher_id', user.id)
            .order('name', ascending: true),
      ]);

      if (!mounted) return;

      final teacherData = results[0] as Map<String, dynamic>;
      final studentsData = results[1] as List<dynamic>;

      setState(() {
        _teacherName = teacherData['full_name'] ?? 'Unknown Teacher';
        _students = List<Map<String, dynamic>>.from(studentsData);
        _filteredStudents = _students;
        _studentCount = _students.length;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading teacher data: $e');
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Failed to load teacher data';
        _isLoading = false;
      });
    }
  }

  void _filterStudents(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredStudents = _students;
      });
      return;
    }

    setState(() {
      _filteredStudents = _students
          .where((student) {
        final name = student['name']?.toString().toLowerCase() ?? '';
        final className = student['class_name']?.toString().toLowerCase() ?? '';
        final searchQuery = query.toLowerCase();
        return name.contains(searchQuery) || className.contains(searchQuery);
      })
          .toList();
    });
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

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final name = student['name']?.toString() ?? 'Unknown';
    final age = student['age']?.toString() ?? 'N/A';
    final className = student['class_name']?.toString() ?? 'N/A';
    final studentId = student['id']?.toString() ?? '';
    final displayId = studentId.length > 8 ? studentId.substring(0, 8) : studentId;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Age: $age'),
            Text('Class: $className'),
            if (displayId.isNotEmpty) Text('ID: $displayId'),
          ],
        ),
        isThreeLine: true,
        onTap: () {
          // TODO: Navigate to student details
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Selected student: $name')),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.announcement),
            tooltip: 'Announcements',
            onPressed: () => _navigateToScreen( AnnouncementsScreen() as Widget),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
                onPressed: _loadTeacherData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadTeacherData,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Text(
                'Welcome, $_teacherName',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Students in your class: $_studentCount',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  _buildActionButton(
                    label: 'Take Attendance',
                    icon: Icons.check_circle,
                    onPressed: () => _navigateToScreen( AttendanceScreen()),
                  ),
                  const SizedBox(width: 16),
                  _buildActionButton(
                    label: 'Message Parents',
                    icon: Icons.message,
                    onPressed: () => _navigateToScreen( MessagesScreen()),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Your Students Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your Students',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_filteredStudents.isNotEmpty)
                    Text(
                      '${_filteredStudents.length} students',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Search Bar
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search students by name or class...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: _filterStudents,
              ),
              const SizedBox(height: 16),

              // Students List
              Expanded(
                child: _students.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No students assigned yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Students will appear here once they are assigned to you',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
                    : _filteredStudents.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No students found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try adjusting your search term',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  itemCount: _filteredStudents.length,
                  itemBuilder: (context, index) {
                    return _buildStudentCard(_filteredStudents[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

