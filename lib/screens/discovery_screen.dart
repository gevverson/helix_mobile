import 'package:flutter/material.dart';
import '../config/app_constants.dart';
import '../services/dating_service.dart';
import '../widgets/safety_menu.dart';
import '../widgets/genetic_disclaimer.dart';

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

  // Active filters (null = no filter).
  int? _minAge;
  int? _maxAge;
  String? _city;

  bool get _hasFilters => _minAge != null || _maxAge != null || (_city?.isNotEmpty ?? false);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await DatingService.fetchDiscovery(
      minAge: _minAge,
      maxAge: _maxAge,
      city: _city,
    );
    if (!mounted) return;
    setState(() {
      _candidates = list;
      _index = 0;
      _loading = false;
    });
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: AppConstants.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterSheet(minAge: _minAge, maxAge: _maxAge, city: _city),
    );
    if (result == null) return; // dismissed without applying
    setState(() {
      _minAge = result['min_age'] as int?;
      _maxAge = result['max_age'] as int?;
      _city = result['city'] as String?;
    });
    _load();
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              compatible
                  ? 'You and ${match['name'] ?? 'they'} matched — and you\'re genetically compatible. Their photo is unlocked in Matches. 💚'
                  : 'You matched with ${match['name'] ?? 'them'}, but this pairing carries a higher genetic risk. See the advisory in Matches before going further.',
              style: const TextStyle(color: AppConstants.textSecondary, height: 1.5),
            ),
            if (!compatible) const GeneticDisclaimer(padding: EdgeInsets.only(top: 14)),
          ],
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
      appBar: AppBar(
        title: const Text('Discover'),
        actions: [
          IconButton(
            tooltip: 'Filters',
            icon: Icon(_hasFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
                color: _hasFilters ? AppConstants.accentCyan : AppConstants.textSecondary),
            onPressed: _openFilters,
          ),
        ],
      ),
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
          Text(_hasFilters ? 'No one matches your filters' : 'No more people right now',
              style: const TextStyle(color: AppConstants.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(_hasFilters ? 'Try widening your age range or clearing the city.' : 'Check back later for new matches.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppConstants.textSecondary)),
          const SizedBox(height: 20),
          if (_hasFilters)
            TextButton.icon(
              onPressed: _openFilters,
              icon: const Icon(Icons.filter_alt_outlined, color: AppConstants.accentCyan),
              label: const Text('Adjust filters', style: TextStyle(color: AppConstants.accentCyan)),
            )
          else
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
    final city = c['city'] as String?;
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
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: () => showSafetyMenu(
                context,
                userId: c['user_id'] as String,
                name: name,
                onChanged: _load,
              ),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
                child: const Icon(Icons.more_horiz, color: Colors.white, size: 22),
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
                if (city != null && city.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.place_outlined, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(city, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ],
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

/// Bottom sheet for discovery filters: an age range (18–80, where 80 = "80+")
/// and a coarse city. Returns {min_age, max_age, city} on apply (values are null
/// when unset), or {all null} on clear. Returns null if dismissed.
class _FilterSheet extends StatefulWidget {
  final int? minAge;
  final int? maxAge;
  final String? city;

  const _FilterSheet({this.minAge, this.maxAge, this.city});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  static const double _min = 18;
  static const double _max = 80; // 80 represents "80+" (no upper bound)
  late RangeValues _range;
  late final TextEditingController _cityCtrl;

  @override
  void initState() {
    super.initState();
    _range = RangeValues(
      (widget.minAge ?? _min.toInt()).toDouble().clamp(_min, _max),
      (widget.maxAge ?? _max.toInt()).toDouble().clamp(_min, _max),
    );
    _cityCtrl = TextEditingController(text: widget.city ?? '');
  }

  @override
  void dispose() {
    _cityCtrl.dispose();
    super.dispose();
  }

  String get _maxLabel => _range.end >= _max ? '80+' : '${_range.end.round()}';

  void _apply() {
    final start = _range.start.round();
    final end = _range.end.round();
    final city = _cityCtrl.text.trim();
    Navigator.pop(context, {
      'min_age': start <= _min ? null : start,   // 18 = no lower bound
      'max_age': end >= _max ? null : end,       // 80 = no upper bound
      'city': city.isEmpty ? null : city,
    });
  }

  void _clear() => Navigator.pop(context, {'min_age': null, 'max_age': null, 'city': null});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppConstants.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Filters',
              style: TextStyle(color: AppConstants.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Age', style: TextStyle(color: AppConstants.textSecondary, fontWeight: FontWeight.w600)),
              Text('${_range.start.round()} – $_maxLabel',
                  style: const TextStyle(color: AppConstants.accentCyan, fontWeight: FontWeight.w700)),
            ],
          ),
          RangeSlider(
            values: _range,
            min: _min,
            max: _max,
            divisions: (_max - _min).toInt(),
            activeColor: AppConstants.accentCyan,
            inactiveColor: AppConstants.borderColor,
            labels: RangeLabels('${_range.start.round()}', _maxLabel),
            onChanged: (v) => setState(() => _range = v),
          ),
          const SizedBox(height: 12),
          const Text('City', style: TextStyle(color: AppConstants.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _cityCtrl,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(color: AppConstants.textPrimary),
            decoration: InputDecoration(
              hintText: 'e.g. Nairobi',
              hintStyle: const TextStyle(color: AppConstants.textMuted),
              filled: true,
              fillColor: AppConstants.bgElevated,
              prefixIcon: const Icon(Icons.place_outlined, color: AppConstants.textMuted),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (_) => _apply(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clear,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppConstants.borderColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Clear', style: TextStyle(color: AppConstants.textSecondary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _apply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.accentCyan,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Apply', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
