import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AttendanceScreen extends StatefulWidget {
  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String? _selectedStudentId;
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _recentAttendance = [];
  Map<String, dynamic>? _currentStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _loadRecentAttendance();
  }

  Future<void> _loadStudents() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final studentsData = await Supabase.instance.client
            .from('students')
            .select('id, name')
            .eq('teacher_id', user.id);

        setState(() {
          _students = List<Map<String, dynamic>>.from(studentsData);
        });
      }
    } catch (e) {
      print('Error loading students: $e');
    }
  }

  Future<void> _loadRecentAttendance() async {
    try {
      final attendanceData = await Supabase.instance.client
          .from('attendance')
          .select('*, students(name)')
          .order('created_at', ascending: false)
          .limit(10);

      setState(() {
        _recentAttendance = List<Map<String, dynamic>>.from(attendanceData);
      });
    } catch (e) {
      print('Error loading attendance: $e');
    }
  }

  Future<void> _loadCurrentStatus() async {
    if (_selectedStudentId == null) return;

    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final statusData = await Supabase.instance.client
          .from('attendance')
          .select('*, students(name)')
          .eq('student_id', _selectedStudentId!)
          .gte('created_at', today)
          .limit(1);

      setState(() {
        _currentStatus = statusData.isNotEmpty ? statusData[0] : null;
      });
    } catch (e) {
      print('Error loading current status: $e');
    }
  }

  Future<void> _markAttendance(String action) async {
    if (_selectedStudentId == null) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final timeString = DateFormat('HH:mm').format(now);

      if (action == 'check_in') {
        await Supabase.instance.client.from('attendance').insert({
          'student_id': _selectedStudentId,
          'status': 'present',
          'check_in_time': timeString,
          'date': DateFormat('yyyy-MM-dd').format(now),
        });
      } else {
        // Update existing record with check-out time
        if (_currentStatus != null) {
          await Supabase.instance.client
              .from('attendance')
              .update({'check_out_time': timeString})
              .eq('id', _currentStatus!['id']);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Attendance marked successfully!')),
      );

      _loadCurrentStatus();
      _loadRecentAttendance();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking attendance: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Attendance')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Student Select',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedStudentId,
              decoration: InputDecoration(
                labelText: 'Choose Student',
                border: OutlineInputBorder(),
              ),
              items: _students
                  .map((student) => DropdownMenuItem<String>(
                value: student['id']?.toString(),
                child: Text(student['name']?.toString() ?? 'Unknown'),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedStudentId = value);
                if (value != null) _loadCurrentStatus();
              },
            ),
            SizedBox(height: 24),

            if (_selectedStudentId != null) ...[
              Text(
                'Current Status',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Student: ${_currentStatus?['students']?['name'] ?? 'Unknown'}'),
                      SizedBox(height: 8),
                      Text('Status: ${_currentStatus != null ? 'Checked In' : 'Not Checked In'}'),
                      SizedBox(height: 8),
                      Text('Date: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}'),
                      SizedBox(height: 8),
                      Text('Time: ${DateFormat('HH:mm').format(DateTime.now())}'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),

              Text(
                'Attendance Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading || _currentStatus != null
                          ? null
                          : () => _markAttendance('check_in'),
                      icon: Icon(Icons.login),
                      label: Text('Check In'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading || _currentStatus == null
                          ? null
                          : () => _markAttendance('check_out'),
                      icon: Icon(Icons.logout),
                      label: Text('Check Out'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              Text(
                'Recent Attendance',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),

              Expanded(
                child: ListView.builder(
                  itemCount: _recentAttendance.length,
                  itemBuilder: (context, index) {
                    final attendance = _recentAttendance[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 12.0),
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              attendance['students']?['name'] ?? 'Unknown Student',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Text('Status: ${attendance['status']}'),
                                SizedBox(width: 16),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 4.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: attendance['status'] == 'present'
                                        ? Colors.green
                                        : Colors.red,
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Text(
                                    attendance['status'].toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Check In: ${attendance['check_in_time'] ?? 'N/A'}',
                              style: TextStyle(fontSize: 14),
                            ),
                            if (attendance['check_out_time'] != null)
                              Text(
                                'Check Out: ${attendance['check_out_time']}',
                                style: TextStyle(fontSize: 14),
                              ),
                            SizedBox(height: 8),
                            Text(
                              attendance['date'] ??
                                  DateTime.parse(attendance['created_at'])
                                      .toLocal()
                                      .toString()
                                      .split(' ')[0],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}