import 'package:flutter/material.dart';
import '../config/app_constants.dart';
import '../services/dating_service.dart';

/// Browse potential matches — one card at a time. Photos are blurred; a
/// compatibility badge is shown up front. Liking someone who liked you = a match.
class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<Map<String, dynamic>> _candidates = [];
  int _index = 0;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await DatingService.fetchDiscovery();
    if (!mounted) return;
    setState(() {
      _candidates = list;
      _index = 0;
      _loading = false;
    });
  }

  void _pass() {
    if (_busy) return;
    setState(() => _index++);
  }

  Future<void> _like() async {
    if (_busy || _index >= _candidates.length) return;
    final cand = _candidates[_index];
    setState(() => _busy = true);
    final result = await DatingService.likeUser(cand['user_id'] as String);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _index++;
    });
    if (result != null && result['matched'] == true) {
      _showMatchDialog(result['match'] as Map<String, dynamic>);
    }
  }

  void _showMatchDialog(Map<String, dynamic> match) {
    final compatible = match['can_unblur'] == true;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            ShaderMask(
              shaderCallback: (b) => AppConstants.purpleGradient.createShader(b),
              child: const Icon(Icons.favorite, color: Colors.white),
            ),
            const SizedBox(width: 8),
            const Text("It's a match!",
                style: TextStyle(color: AppConstants.textPrimary, fontSize: 18)),
          ],
        ),
        content: Text(
          compatible
              ? 'You and ${match['name'] ?? 'they'} matched — and you\'re genetically compatible. Their photo is unlocked in Matches. 💚'
              : 'You matched with ${match['name'] ?? 'them'}, but this pairing carries a genetic risk. See the advisory in Matches before going further.',
          style: const TextStyle(color: AppConstants.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep browsing',
                style: TextStyle(color: AppConstants.accentCyan)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppConstants.bgPrimary,
      appBar: AppBar(title: const Text('Discover')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppConstants.bgGradient),
        child: SafeArea(child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppConstants.accentCyan),
      );
    }
    if (_index >= _candidates.length) {
      return _empty();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        children: [
          Expanded(child: _card(_candidates[_index])),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _actionButton(
                icon: Icons.close,
                color: AppConstants.textSecondary,
                onTap: _pass,
              ),
              const SizedBox(width: 40),
              _actionButton(
                icon: Icons.favorite,
                color: AppConstants.accentPink,
                onTap: _like,
                filled: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.explore_off_outlined, color: AppConstants.textMuted, size: 56),
          const SizedBox(height: 16),
          const Text('No more people right now',
              style: TextStyle(color: AppConstants.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Check back later for new matches.',
              style: TextStyle(color: AppConstants.textSecondary)),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh, color: AppConstants.accentCyan),
            label: const Text('Refresh', style: TextStyle(color: AppConstants.accentCyan)),
          ),
        ],
      ),
    );
  }

  Widget _card(Map<String, dynamic> c) {
    final name = c['name'] as String? ?? 'Someone';
    final age = c['age'] as int?;
    final photoUrl = c['photo_url'] as String?;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (photoUrl != null)
            Image.network(
              photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _photoPlaceholder(name),
              loadingBuilder: (ctx, child, prog) =>
                  prog == null ? child : _photoPlaceholder(name),
            )
          else
            _photoPlaceholder(name),
          // gradient for legibility
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _compatBadge(c['compatibility'] as String?),
                const SizedBox(height: 12),
                Text(
                  age != null ? '$name, $age' : name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text('Photo unlocks when you match & are compatible',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoPlaceholder(String name) {
    return Container(
      color: AppConstants.bgCard,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: AppConstants.textMuted,
            fontSize: 72,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _compatBadge(String? status) {
    late Color color;
    late String label;
    late IconData icon;
    switch (status) {
      case 'safe':
        color = AppConstants.successColor;
        label = 'Compatible';
        icon = Icons.check_circle;
        break;
      case 'caution':
        color = AppConstants.warningColor;
        label = 'Caution';
        icon = Icons.info;
        break;
      case 'danger':
        color = AppConstants.errorColor;
        label = 'High genetic risk';
        icon = Icons.warning_amber_rounded;
        break;
      default:
        color = AppConstants.textMuted;
        label = 'Compatibility unknown';
        icon = Icons.help_outline;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    return GestureDetector(
      onTap: _busy ? null : onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? color : AppConstants.bgSecondary,
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12),
          ],
        ),
        child: Icon(icon, color: filled ? Colors.white : color, size: 30),
      ),
    );
  }
}
