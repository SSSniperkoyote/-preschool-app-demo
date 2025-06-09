import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AssignTeacherScreen extends StatefulWidget {
  @override
  _AssignTeacherScreenState createState() => _AssignTeacherScreenState();
}

class _AssignTeacherScreenState extends State<AssignTeacherScreen> {
  String? _selectedStudentId;
  String? _selectedTeacherId;
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _recentAssignments = [];
  bool _isLoading = false;
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isInitialLoading = true);

      // Load students with error handling
      final studentsResponse = await Supabase.instance.client
          .from('students')
          .select('id, name, class_name')
          .order('name', ascending: true);

      // Load teachers with error handling
      final teachersResponse = await Supabase.instance.client
          .from('users')
          .select('id, full_name')
          .eq('role', 'teacher')
          .order('full_name', ascending: true);

      // Load recent assignments with proper join and error handling
      final assignmentsResponse = await Supabase.instance.client
          .from('students')
          .select('id, name, class_name, teacher_id, created_at, users!students_teacher_id_fkey(full_name)')
          .not('teacher_id', 'is', null)
          .order('created_at', ascending: false)
          .limit(5);

      if (mounted) {
        setState(() {
          _students = studentsResponse is List
              ? List<Map<String, dynamic>>.from(studentsResponse)
              : [];
          _teachers = teachersResponse is List
              ? List<Map<String, dynamic>>.from(teachersResponse)
              : [];
          _recentAssignments = assignmentsResponse is List
              ? List<Map<String, dynamic>>.from(assignmentsResponse)
              : [];
          _isInitialLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() => _isInitialLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadData,
            ),
          ),
        );
      }
    }
  }

  Future<void> _updateAssignment() async {
    if (_selectedStudentId == null || _selectedTeacherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select both student and teacher'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Update the student's teacher assignment
      await Supabase.instance.client
          .from('students')
          .update({'teacher_id': _selectedTeacherId})
          .eq('id', _selectedStudentId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Assignment updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Refresh data
      await _loadData();

      // Clear selections
      if (mounted) {
        setState(() {
          _selectedStudentId = null;
          _selectedTeacherId = null;
        });
      }
    } catch (e) {
      print('Error updating assignment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating assignment: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<Map<String, dynamic>> items,
    required String valueKey,
    required String displayKey,
    String? secondaryDisplayKey,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: items.map((item) {
        final displayText = secondaryDisplayKey != null
            ? '${item[displayKey]?.toString() ?? 'Unknown'} (${item[secondaryDisplayKey]?.toString() ?? 'N/A'})'
            : item[displayKey]?.toString() ?? 'Unknown';

        return DropdownMenuItem<String>(
          value: item[valueKey]?.toString(),
          child: Text(displayText),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Please select $label' : null,
      isExpanded: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Assign Teacher'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading data...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Assign Teacher'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.assignment_ind, color: Theme.of(context).primaryColor),
                          SizedBox(width: 8),
                          Text(
                            'Student-Teacher Assignment',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Student Dropdown
                      _buildDropdownField(
                        label: 'Select Student',
                        icon: Icons.person,
                        value: _selectedStudentId,
                        items: _students,
                        valueKey: 'id',
                        displayKey: 'name',
                        secondaryDisplayKey: 'class_name',
                        onChanged: (value) => setState(() => _selectedStudentId = value),
                      ),
                      SizedBox(height: 16),

                      // Teacher Dropdown
                      _buildDropdownField(
                        label: 'Select Teacher',
                        icon: Icons.school,
                        value: _selectedTeacherId,
                        items: _teachers,
                        valueKey: 'id',
                        displayKey: 'full_name',
                        onChanged: (value) => setState(() => _selectedTeacherId = value),
                      ),
                      SizedBox(height: 24),

                      // Update Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _updateAssignment,
                          icon: _isLoading
                              ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : Icon(Icons.assignment_turned_in),
                          label: Text(_isLoading ? 'Updating...' : 'Update Assignment'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Recent Assignments Section
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.history, color: Theme.of(context).primaryColor),
                          SizedBox(width: 8),
                          Text(
                            'Recent Assignments',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Recent Assignments List
                      _recentAssignments.isEmpty
                          ? Container(
                        height: 200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.assignment_late,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No recent assignments found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _loadData,
                                child: Text('Refresh'),
                              ),
                            ],
                          ),
                        ),
                      )
                          : Column(
                        children: _recentAssignments.map((assignment) {
                          return Card(
                            margin: EdgeInsets.only(bottom: 8),
                            elevation: 1,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).primaryColor,
                                child: Text(
                                  (assignment['name']?.toString() ?? 'U')[0].toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                assignment['name']?.toString() ?? 'Unknown Student',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Class: ${assignment['class_name']?.toString() ?? 'No Class'}'),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.person, size: 16, color: Colors.grey[600]),
                                      SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'Teacher: ${assignment['users']?['full_name']?.toString() ?? 'No teacher assigned'}',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 20,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}