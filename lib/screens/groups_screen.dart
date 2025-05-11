import 'package:bs/services/firebase_service.dart';
import 'package:bs/models/group.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:developer' as developer;

import '../widgets/custom_scaffold.dart';

class GroupsScreen extends StatefulWidget {
  final String userId;

  const GroupsScreen({super.key, required this.userId});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final FirebaseDataService _dataService = FirebaseDataService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    developer.log('Initializing GroupsScreen for user: ${widget.userId}', name: 'GroupsScreen');
  }

  @override
  void dispose() {
    developer.log('Disposing GroupsScreen', name: 'GroupsScreen');
    super.dispose();
  }

  void _onPopInvokedWithResult(bool didPop, dynamic result) {
    developer.log('Pop invoked, loading: $_isLoading', name: 'GroupsScreen');
    if (didPop) return;
    if (_isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait, loading groups')),
      );
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onPopInvokedWithResult,
      child: CustomScaffold(
        userId: widget.userId, // Pass userId to CustomScaffold
        title: 'Grupos',
        showBackButton: true,
        showMenuButton: true, // RadialMenu is handled by ShellRoute
        body: FutureBuilder<List<Group>>(
          future: _dataService.getUserGroups(widget.userId),
          builder: (context, snapshot) {
            developer.log(
              'FutureBuilder state: ${snapshot.connectionState}, '
                  'hasData: ${snapshot.hasData}, hasError: ${snapshot.hasError}',
              name: 'GroupsScreen',
            );

            // Update _isLoading based on connection state
            _isLoading = snapshot.connectionState == ConnectionState.waiting;

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: colorScheme.onSurface,
                ),
              );
            }

            if (snapshot.hasError) {
              developer.log(
                'Error loading groups: ${snapshot.error}, stack: ${snapshot.stackTrace}',
                name: 'GroupsScreen',
              );
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: colorScheme.onSecondary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Trigger rebuild to retry
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final groups = snapshot.data ?? [];
            developer.log('Groups loaded: ${groups.length}', name: 'GroupsScreen');

            if (groups.isEmpty) {
              return Center(
                child: Text(
                  'No estás en ningún grupo',
                  style: TextStyle(color: colorScheme.onSecondary),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return Card(
                  key: ValueKey('group_${group.groupId}'), // Add key for stability
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  color: colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: colorScheme.onSecondary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.surface.withValues(alpha: 0.1),
                      backgroundImage: group.imageUrl != null && group.imageUrl!.isNotEmpty
                          ? NetworkImage(group.imageUrl!)
                          : null,
                      child: group.imageUrl == null || group.imageUrl!.isEmpty
                          ? Icon(
                        Icons.group,
                        color: colorScheme.onSurface,
                      )
                          : null,
                    ),
                    title: Text(
                      group.name,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      group.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colorScheme.onSecondary),
                    ),
                    trailing: Text(
                      '${group.memberIds.length} miembros',
                      style: TextStyle(color: colorScheme.onSecondary),
                    ),
                    onTap: () {
                      context.go('/group/${group.groupId}'); // Navigate to group detail
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}