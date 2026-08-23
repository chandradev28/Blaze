import 'package:flutter/material.dart';

import '../controllers/blaze_controller.dart';
import '../models/blaze_theme.dart';
import '../services/speed_test_service.dart';
import '../widgets/blaze_gauge.dart';
import '../widgets/blaze_ui.dart';

class GarageScreen extends StatefulWidget {
  const GarageScreen({required this.controller, super.key});

  final BlazeController controller;

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  late BlazeTheme _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.controller.activeTheme;
  }

  void _update(BlazeTheme theme) {
    setState(() => _draft = theme);
    widget.controller.selectTheme(theme);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final theme = widget.controller.activeTheme;
        return Container(
          color: theme.background,
          child: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                  sliver:
                      SliverToBoxAdapter(child: _GarageHeader(theme: theme)),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: BlazeCard(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                      child: Column(
                        children: [
                          SizedBox(
                              height: 300,
                              child: BlazeGauge(
                                  theme: _draft,
                                  value: _draft.maxSpeed * 0.64,
                                  phase: TestPhase.download)),
                          Text(_draft.name,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          Text('Live preview',
                              style: TextStyle(
                                  color: _draft.secondary,
                                  fontSize: 11,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
                  sliver: SliverToBoxAdapter(
                      child: BlazeSectionTitle(title: 'Presets')),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 202,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      scrollDirection: Axis.horizontal,
                      itemCount: BlazeTheme.presets.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final preset = BlazeTheme.presets[index];
                        return ThemePreview(
                          theme: preset,
                          selected: preset.id == theme.id,
                          onTap: () => _update(preset),
                        );
                      },
                    ),
                  ),
                ),
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                  sliver: SliverToBoxAdapter(
                      child: BlazeSectionTitle(title: 'Dial style')),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: Wrap(
                      spacing: 9,
                      runSpacing: 9,
                      children: GaugeStyle.values.map((style) {
                        final selected = _draft.gaugeStyle == style;
                        return ChoiceChip(
                          selected: selected,
                          label: Text(style.label),
                          avatar: Icon(_styleIcon(style), size: 16),
                          onSelected: (_) =>
                              _update(_draft.copyWith(gaugeStyle: style)),
                          selectedColor: _draft.primary.withOpacity(0.24),
                          labelStyle: TextStyle(
                              color: selected ? Colors.white : Colors.white70,
                              fontWeight: FontWeight.w700),
                          side: BorderSide(
                              color: selected
                                  ? _draft.primary
                                  : Colors.white.withOpacity(0.10)),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
                  sliver: SliverToBoxAdapter(
                      child: BlazeSectionTitle(title: 'Accent color')),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  sliver: SliverToBoxAdapter(
                      child: _ColorSelector(draft: _draft, onChanged: _update)),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: BlazeCard(
                      child: Column(
                        children: [
                          _SliderRow(
                            label: 'Speed scale',
                            valueLabel: '${_draft.maxSpeed} Mbps',
                            value: _draft.maxSpeed.toDouble(),
                            min: 500,
                            max: 5000,
                            divisions: 9,
                            onChanged: (value) => _update(
                                _draft.copyWith(maxSpeed: value.round())),
                          ),
                          const SizedBox(height: 8),
                          _SliderRow(
                            label: 'Motion intensity',
                            valueLabel: '${(_draft.motion * 100).round()}%',
                            value: _draft.motion,
                            min: 0.2,
                            max: 1,
                            divisions: 8,
                            onChanged: (value) =>
                                _update(_draft.copyWith(motion: value)),
                          ),
                          const Divider(height: 26, color: Colors.white12),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Technical grid',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text(
                                'Add technical data lines to the dial',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.42),
                                    fontSize: 12)),
                            value: _draft.showGrid,
                            activeColor: _draft.primary,
                            onChanged: (value) =>
                                _update(_draft.copyWith(showGrid: value)),
                          ),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Edge glow',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text('Make the signal feel alive',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.42),
                                    fontSize: 12)),
                            value: _draft.showGlow,
                            activeColor: _draft.primary,
                            onChanged: (value) =>
                                _update(_draft.copyWith(showGlow: value)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  sliver: SliverToBoxAdapter(
                    child: SizedBox(
                      height: 54,
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          widget.controller.saveTheme(_draft);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Dashboard saved to your garage')));
                        },
                        icon: const Icon(Icons.bookmark_add_outlined),
                        label: const Text('SAVE DASHBOARD',
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1)),
                        style: FilledButton.styleFrom(
                          backgroundColor: _draft.primary,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(17)),
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.controller.savedThemes.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    sliver: SliverToBoxAdapter(
                      child: BlazeCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const BlazeSectionTitle(title: 'Saved builds'),
                            const SizedBox(height: 12),
                            ...widget.controller.savedThemes
                                .map((saved) => ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: CircleAvatar(
                                          backgroundColor: saved.primary,
                                          child: const Icon(Icons.speed,
                                              color: Colors.black, size: 18)),
                                      title: Text(saved.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w800)),
                                      subtitle: Text(saved.subtitle),
                                      trailing: IconButton(
                                          onPressed: () => widget.controller
                                              .deleteTheme(saved),
                                          icon: const Icon(
                                              Icons.delete_outline_rounded)),
                                      onTap: () => _update(saved),
                                    )),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _styleIcon(GaugeStyle style) {
    switch (style) {
      case GaugeStyle.classic:
        return Icons.speed_rounded;
      case GaugeStyle.f1:
        return Icons.sports_motorsports_rounded;
      case GaugeStyle.motoGp:
        return Icons.two_wheeler_rounded;
      case GaugeStyle.electric:
        return Icons.bolt_rounded;
      case GaugeStyle.neon:
        return Icons.auto_awesome_rounded;
    }
  }
}

class _GarageHeader extends StatelessWidget {
  const _GarageHeader({required this.theme});

  final BlazeTheme theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('BLAZE GARAGE',
            style: TextStyle(
                color: theme.primary,
                fontSize: 11,
                letterSpacing: 2.2,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text('Build your dashboard.',
            style: TextStyle(
                fontSize: 29, fontWeight: FontWeight.w900, height: 1.05)),
        const SizedBox(height: 8),
        Text(
            'Pick a machine, tune the dial, and make every test feel like yours.',
            style:
                TextStyle(color: Colors.white.withOpacity(0.50), height: 1.35)),
      ],
    );
  }
}

class _ColorSelector extends StatelessWidget {
  const _ColorSelector({required this.draft, required this.onChanged});

  final BlazeTheme draft;
  final ValueChanged<BlazeTheme> onChanged;

  static const colors = [
    Color(0xFFFF6A3D),
    Color(0xFFFF3B30),
    Color(0xFFFFC857),
    Color(0xFF42D6FF),
    Color(0xFF8BFF74),
    Color(0xFFFF4ECD),
    Color(0xFF9B8CFF),
    Color(0xFFFFFFFF),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      children: colors.map((color) {
        final selected = draft.primary.value == color.value;
        return GestureDetector(
          onTap: () => onChanged(
              draft.copyWith(primary: color, secondary: _secondary(color))),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                  color: selected ? Colors.white : Colors.transparent,
                  width: 3),
              boxShadow: selected
                  ? [BoxShadow(color: color.withOpacity(0.45), blurRadius: 14)]
                  : null,
            ),
            child: selected
                ? const Icon(Icons.check, color: Colors.black, size: 18)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Color _secondary(Color color) {
    if (color == const Color(0xFFFFFFFF)) return const Color(0xFFE0E0E0);
    return Color.lerp(color, Colors.white, 0.55) ?? Colors.white;
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow(
      {required this.label,
      required this.valueLabel,
      required this.value,
      required this.min,
      required this.max,
      required this.divisions,
      required this.onChanged});

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
            Text(valueLabel,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12)),
          ],
        ),
        Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged),
      ],
    );
  }
}
