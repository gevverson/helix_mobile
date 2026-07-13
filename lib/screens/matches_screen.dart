import 'package:flutter/material.dart';
import '../config/app_constants.dart';
import '../services/dating_service.dart';
import '../widgets/safety_menu.dart';

/// Your matches. Photos are clear when you're genetically compatible, and stay
/// blurred with a health advisory when the pairing is high-risk.
class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<Map<String, dynamic>> _matches = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await DatingService.fetchMatches();
    if (!mounted) return;
    setState(() {
      _matches = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppConstants.bgPrimary,
      appBar: AppBar(title: const Text('Matches')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppConstants.bgGradient),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppConstants.accentCyan))
              : _matches.isEmpty
                  ? _empty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppConstants.accentCyan,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _matches.length,
                        itemBuilder: (ctx, i) => _matchCard(_matches[i]),
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite_border, color: AppConstants.textMuted, size: 56),
          const SizedBox(height: 16),
          const Text('No matches yet',
              style: TextStyle(color: AppConstants.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Like people in Discover — when they like you back, they show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppConstants.textSecondary)),
        ],
      ),
    );
  }

  Widget _matchCard(Map<String, dynamic> m) {
    final name = m['name'] as String? ?? 'Someone';
    final age = m['age'] as int?;
    final photoUrl = m['photo_url'] as String?;
    final canUnblur = m['can_unblur'] == true;
    final status = m['compatibility'] as String?;
    final message = m['message'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppConstants.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppConstants.borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (photoUrl != null)
                  Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _placeholder(name),
                    loadingBuilder: (ctx, child, prog) =>
                        prog == null ? child : _placeholder(name),
                  )
                else
                  _placeholder(name),
                if (!canUnblur)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_outline, color: Colors.white, size: 13),
                          SizedBox(width: 4),
                          Text('Locked', style: TextStyle(color: Colors.white, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        age != null ? '$name, $age' : name,
                        style: const TextStyle(
                          color: AppConstants.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _statusChip(status),
                    GestureDetector(
                      onTap: () => showSafetyMenu(
                        context,
                        userId: m['user_id'] as String,
                        name: name,
                        onChanged: _load,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(Icons.more_horiz, color: AppConstants.textMuted, size: 20),
                      ),
                    ),
                  ],
                ),
                if (message != null && !canUnblur) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppConstants.errorColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppConstants.errorColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.health_and_safety_outlined,
                            color: AppConstants.errorColor, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            message,
                            style: const TextStyle(
                              color: AppConstants.errorColor,
                              fontSize: 12.5,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(String name) {
    return Container(
      color: AppConstants.bgElevated,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(color: AppConstants.textMuted, fontSize: 56, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _statusChip(String? status) {
    late Color color;
    late String label;
    switch (status) {
      case 'safe':
        color = AppConstants.successColor;
        label = 'Compatible';
        break;
      case 'caution':
        color = AppConstants.warningColor;
        label = 'Caution';
        break;
      case 'danger':
        color = AppConstants.errorColor;
        label = 'High risk';
        break;
      default:
        color = AppConstants.textMuted;
        label = 'Unknown';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}
