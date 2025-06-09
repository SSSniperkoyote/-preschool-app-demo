import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_dashboard.dart' hide AnnouncementsScreen;
import 'messages_screen.dart';
import 'announcements_screen.dart';

class ParentDashboard extends StatefulWidget {
  @override
  _ParentDashboardState createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  String _parentName = '';
  List<Map<String, dynamic>> _children = [];
  List<Map<String, dynamic>> _attendanceRecords = [];

  @override
  void initState() {
    super.initState();
    _loadParentData();
  }

  Future<void> _loadParentData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Get parent info
        final parentData = await Supabase.instance.client
            .from('users')
            .select('full_name')
            .eq('id', user.id)
            .single();

        // Get children
        final childrenData = await Supabase.instance.client
            .from('students')
            .select('*, users!students_teacher_id_fkey(full_name)')
            .eq('parent_id', user.id);

        // Get attendance records for children
        if (childrenData.isNotEmpty) {
          final studentIds = childrenData.map((c) => c['id']).toList();
          final attendanceData = await Supabase.instance.client
              .from('attendance')
              .select('*, students(name)')
              .inFilter('student_id', studentIds)
              .order('created_at', ascending: false)
              .limit(10);

          setState(() {
            _parentName = parentData['full_name'];
            _children = List<Map<String, dynamic>>.from(childrenData);
            _attendanceRecords = List<Map<String, dynamic>>.from(attendanceData);
          });
        } else {
          setState(() {
            _parentName = parentData['full_name'];
            _children = [];
            _attendanceRecords = [];
          });
        }
      }
    } catch (e) {
      print('Error loading parent data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Parent Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.announcement),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AnnouncementsScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.message),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MessagesScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, $_parentName',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),

            // Child Information
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Child Information',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    if (_children.isEmpty)
                      Text('No children registered')
                    else
                      ..._children.map((child) => Card(
                        margin: EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(Icons.child_care),
                          title: Text(child['name']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Class: ${child['class_name']}'),
                              Text('Teacher: ${child['users']?['full_name'] ?? 'Not assigned'}'),
                            ],
                          ),
                        ),
                      )).toList(),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Attendance Records
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attendance Records',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    Container(
                      height: 200,
                      child: _attendanceRecords.isEmpty
                          ? Center(child: Text('No attendance records found'))
                          : ListView.builder(
                        itemCount: _attendanceRecords.length,
                        itemBuilder: (context, index) {
                          final record = _attendanceRecords[index];
                          return ListTile(
                            leading: Icon(
                              record['status'] == 'present'
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: record['status'] == 'present'
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            title: Text(record['students']['name']),
                            subtitle: Text(
                                '${record['status']} - ${DateTime.parse(record['created_at']).toLocal().toString().split(' ')[0]}'
                            ),
                            trailing: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (record['check_in_time'] != null)
                                  Text('In: ${record['check_in_time']}'),
                                if (record['check_out_time'] != null)
                                  Text('Out: ${record['check_out_time']}'),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}