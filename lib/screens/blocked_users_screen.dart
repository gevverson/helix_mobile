import 'package:flutter/material.dart';
import '../config/app_constants.dart';
import '../services/dating_service.dart';

/// Lists people the user has blocked, with the option to unblock.
class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  List<Map<String, dynamic>> _blocked = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await DatingService.fetchBlocks();
    if (!mounted) return;
    setState(() {
      _blocked = list;
      _loading = false;
    });
  }

  Future<void> _unblock(String id) async {
    final ok = await DatingService.unblockUser(id);
    if (ok && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.bgPrimary,
      appBar: AppBar(title: const Text('Blocked Users')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppConstants.bgGradient),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppConstants.accentCyan))
              : _blocked.isEmpty
                  ? const Center(
                      child: Text(
                        "You haven't blocked anyone.",
                        style: TextStyle(color: AppConstants.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _blocked.length,
                      itemBuilder: (ctx, i) {
                        final b = _blocked[i];
                        final name = b['name'] as String? ?? 'User';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: AppConstants.bgCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppConstants.borderColor),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppConstants.bgElevated,
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(color: AppConstants.textSecondary),
                              ),
                            ),
                            title: Text(name, style: const TextStyle(color: AppConstants.textPrimary)),
                            trailing: TextButton(
                              onPressed: () => _unblock(b['user_id'] as String),
                              child: const Text('Unblock',
                                  style: TextStyle(color: AppConstants.accentCyan)),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}
