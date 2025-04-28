import 'package:bs/services/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:developer' as developer;

class InterestSelectionScreen extends StatefulWidget {
  final String userId;

  const InterestSelectionScreen({super.key, required this.userId});

  @override
  State<InterestSelectionScreen> createState() => _InterestSelectionScreenState();
}

class _InterestSelectionScreenState extends State<InterestSelectionScreen> {
  final FirebaseDataService _dataService = FirebaseDataService();
  final List<String> _availableInterests = [
    'Photography',
    'Travel',
    'Music',
    'Art',
    'Sports'
  ];
  final List<String> _selectedInterests = [];
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _saveInterests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _dataService.updateUserInterests(widget.userId, _selectedInterests);
      developer.log('Interests saved for user: ${widget.userId}',
          name: 'InterestSelectionScreen');
      if (mounted) {
        context.go('/home');
      }
    } catch (e, stackTrace) {
      developer.log('Error saving interests: $e',
          name: 'InterestSelectionScreen', stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _errorMessage = 'Error saving interests: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Select Interests')),
    body: Scaffold(
    appBar: AppBar(title: const Text('Select Interests')),
    body: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
    children: [
    const Text(
    'Choose your interests',
    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    ),
    const SizedBox(height: 16),
    Expanded(
    child: ListView(
    children: _availableInterests.map((interest) {
    return CheckboxListTile(
    title: Text(interest),
    value: _selectedInterests.contains(interest),
    onChanged: (bool? selected) {
    setState(() {
    if (selected == true) {
    _selectedInterests.add(interest);
    } else {
    _selectedInterests.remove(interest);
    }
    });
    },
    );
    }).toList(),
    ),
    ),
    ElevatedButton(
    onPressed: _isLoading || _selectedInterests.isEmpty
    ? null
        : _saveInterests,
    style: ElevatedButton.styleFrom(
    minimumSize: const Size(double.infinity, 48),
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    ),
    ),
    child: const Text('Save Interests'),
    ),
    if (_isLoading)
    const Padding(
    padding: EdgeInsets.only(top: 16),
    child: CircularProgressIndicator(),
    ),
    if (_errorMessage != null)
    Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Text(
    _errorMessage!,
    style: TextStyle(color: Theme.of(context).colorScheme.error),
    ),
    ),
    ],
    ),
    ),
    ));
  }
}