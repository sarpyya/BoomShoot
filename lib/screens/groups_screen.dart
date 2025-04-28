import 'package:bs/services/firebase_service.dart';
import 'package:bs/models/group.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:go_router/go_router.dart';
import 'dart:developer' as developer;

import '../widgets/custom_scaffold.dart';
import '../widgets/radial_menu.dart';

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
    _dataService.dispose();
    super.dispose();
  }

  void _showRadialMenu(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.20),
      builder: (context) => RadialMenu(userId: widget.userId),
    );
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onPopInvokedWithResult,
      child: CustomScaffold(
        title: 'Grupos',
        showBackButton: true,
        showMenuButton: true,
        onMenuPressed: () => _showRadialMenu(context),
        floatingActionButton: SpeedDial(
          icon: Icons.add,
          activeIcon: Icons.close,
          children: [
            SpeedDialChild(
              child: const Icon(Icons.event),
              label: 'Crear Evento',
              onTap: () => context.go('/create_event'),
            ),
            SpeedDialChild(
              child: const Icon(Icons.group),
              label: 'Crear Grupo',
              onTap: () => context.go('/create_group'),
            ),
          ],
        ),
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
              return const Center(child: CircularProgressIndicator());
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
                    Text('Error: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Trigger rebuild to retry
                        setState(() {});
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final groups = snapshot.data ?? [];
            developer.log('Groups loaded: ${groups.length}', name: 'GroupsScreen');

            if (groups.isEmpty) {
              return const Center(child: Text('No estás en ningún grupo'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: group.imageUrl != null
                          ? NetworkImage(group.imageUrl!)
                          : null,
                      child: group.imageUrl == null ? const Icon(Icons.group) : null,
                    ),
                    title: Text(group.name),
                    subtitle: Text(
                      group.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text('${group.memberIds.length} miembros'),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Grupo: ${group.name}')),
                      );
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