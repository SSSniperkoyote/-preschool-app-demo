import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({Key? key}) : super(key: key);

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _classController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedTeacherId;
  String? _selectedParentId;
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _parents = [];
  bool _isLoading = false;
  bool _isDataLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUsersData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _classController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadUsersData() async {
    if (!mounted) return;

    setState(() {
      _isDataLoading = true;
      _errorMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;

      // Check if user is authenticated
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Load teachers and parents concurrently
      final results = await Future.wait([
        supabase
            .from('users')
            .select('id, full_name')
            .eq('role', 'teacher')
            .not('full_name', 'is', null),
        supabase
            .from('users')
            .select('id, full_name')
            .eq('role', 'parent')
            .not('full_name', 'is', null),
      ]);

      if (!mounted) return;

      setState(() {
        _teachers = List<Map<String, dynamic>>.from(results[0])
          ..sort((a, b) => (a['full_name'] ?? '').compareTo(b['full_name'] ?? ''));
        _parents = List<Map<String, dynamic>>.from(results[1])
          ..sort((a, b) => (a['full_name'] ?? '').compareTo(b['full_name'] ?? ''));
        _isDataLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading users: $e');
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Failed to load users data';
        _isDataLoading = false;
      });
    }
  }

  String? _validateName(String? value) {
    if (value?.trim().isEmpty ?? true) {
      return 'Name is required';
    }
    if (value!.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return 'Name must be less than 50 characters';
    }
    // Check for valid characters (letters, spaces, hyphens, apostrophes)
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(value.trim())) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }
    return null;
  }

  String? _validateAge(String? value) {
    if (value?.trim().isEmpty ?? true) {
      return 'Age is required';
    }
    final age = int.tryParse(value!.trim());
    if (age == null) {
      return 'Please enter a valid number';
    }
    if (age < 3 || age > 25) {
      return 'Age must be between 3 and 25';
    }
    return null;
  }

  String? _validateClass(String? value) {
    if (value?.trim().isEmpty ?? true) {
      return 'Class is required';
    }
    if (value!.trim().length > 30) {
      return 'Class name must be less than 30 characters';
    }
    return null;
  }

  Future<void> _addStudent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Additional validation for dropdowns
    if (_selectedTeacherId == null) {
      _showErrorSnackBar('Please select a teacher');
      return;
    }

    if (_selectedParentId == null) {
      _showErrorSnackBar('Please select a parent');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      // Check if user is still authenticated
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Authentication expired. Please log in again.');
      }

      // Prepare student data
      final studentData = {
        'name': _nameController.text.trim(),
        'age': int.parse(_ageController.text.trim()),
        'class_name': _classController.text.trim(),
        'teacher_id': _selectedTeacherId,
        'parent_id': _selectedParentId,
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      };

      // Check if student with same name and class already exists
      final existingStudent = await supabase
          .from('students')
          .select('id')
          .eq('name', studentData['name']!)
          .eq('class_name', studentData['class_name']!)
          .maybeSingle();

      if (existingStudent != null) {
        throw Exception(
            'A student with the same name already exists in this class'
        );
      }

      // Insert the student
      await supabase.from('students').insert(studentData);

      if (!mounted) return;

      _showSuccessSnackBar('Student added successfully!');
      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      debugPrint('Error adding student: $e');
      if (!mounted) return;

      String errorMessage = 'Failed to add student';
      if (e.toString().contains('already exists')) {
        errorMessage = 'A student with the same name already exists in this class';
      } else if (e.toString().contains('Authentication')) {
        errorMessage = 'Authentication expired. Please log in again.';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'You do not have permission to add students';
      }

      _showErrorSnackBar(errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<Map<String, dynamic>> items,
    required String displayKey,
    required String valueKey,
    required void Function(String?) onChanged,
    String? emptyMessage,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
      ),
      isExpanded: true,
      items: items.isEmpty
          ? [
        DropdownMenuItem<String>(
          value: null,
          child: Text(
            emptyMessage ?? 'No options available',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      ]
          : items
          .map((item) => DropdownMenuItem<String>(
        value: item[valueKey]?.toString(),
        child: Text(
          item[displayKey]?.toString() ?? 'Unknown',
          overflow: TextOverflow.ellipsis,
        ),
      ))
          .toList(),
      onChanged: items.isEmpty ? null : onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a $label';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Student'),
        elevation: 0,
      ),
      body: _isDataLoading
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
                onPressed: _loadUsersData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Student Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Student Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                textCapitalization: TextCapitalization.words,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r"[a-zA-Z\s\-']"),
                  ),
                ],
                validator: _validateName,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: 'Age *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.cake),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                validator: _validateAge,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _classController,
                decoration: const InputDecoration(
                  labelText: 'Class *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.class_),
                ),
                textCapitalization: TextCapitalization.words,
                validator: _validateClass,
              ),
              const SizedBox(height: 16),

              _buildDropdown(
                label: 'Teacher *',
                value: _selectedTeacherId,
                items: _teachers,
                displayKey: 'full_name',
                valueKey: 'id',
                onChanged: (value) => setState(() => _selectedTeacherId = value),
                emptyMessage: 'No teachers available',
              ),
              const SizedBox(height: 16),

              _buildDropdown(
                label: 'Parent *',
                value: _selectedParentId,
                items: _parents,
                displayKey: 'full_name',
                valueKey: 'id',
                onChanged: (value) => setState(() => _selectedParentId = value),
                emptyMessage: 'No parents available',
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Additional Notes (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                maxLength: 500,
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _addStudent,
                      child: _isLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                          : const Text('Add Student'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text(
                '* Required fields',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}