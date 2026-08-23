import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../controllers/blaze_controller.dart';
import '../models/speed_result.dart';
import '../widgets/blaze_ui.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({required this.controller, super.key});

  final BlazeController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final theme = controller.activeTheme;
        return Container(
          color: Colors.black,
          child: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PERFORMANCE LOG',
                            style: TextStyle(
                                color: theme.primary,
                                fontSize: 11,
                                letterSpacing: 2.2,
                                fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        const Text('Your runs.',
                            style: TextStyle(
                                fontSize: 29, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        Text('Every test, saved locally on this device.',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.50))),
                      ],
                    ),
                  ),
                ),
                if (controller.history.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver:
                        SliverToBoxAdapter(child: _EmptyHistory(theme: theme)),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                        child:
                            _SummaryCard(controller: controller, theme: theme)),
                  ),
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
                    sliver: SliverToBoxAdapter(
                        child: BlazeSectionTitle(title: 'Recent tests')),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList.separated(
                      itemCount: controller.history.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _HistoryTile(
                          result: controller.history[index], theme: theme),
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 30)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.theme});

  final dynamic theme;

  @override
  Widget build(BuildContext context) {
    return BlazeCard(
      padding: const EdgeInsets.fromLTRB(24, 34, 24, 34),
      child: Column(
        children: [
          Icon(Icons.insights_rounded, color: theme.primary, size: 40),
          const SizedBox(height: 16),
          const Text('No runs yet',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
              'Run your first Blaze test and your performance log will start here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.50), height: 1.4)),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.controller, required this.theme});

  final BlazeController controller;
  final dynamic theme;

  @override
  Widget build(BuildContext context) {
    final best = controller.history
        .map((item) => item.download)
        .reduce((a, b) => a > b ? a : b);
    final average = controller.history
            .map((item) => item.download)
            .reduce((a, b) => a + b) /
        controller.history.length;
    return BlazeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ALL-TIME SIGNAL',
              style: TextStyle(
                  color: theme.secondary,
                  fontSize: 10,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          Row(children: [
            MetricTile(
                label: 'Best', value: best.toStringAsFixed(1), unit: 'Mbps'),
            MetricTile(
                label: 'Average',
                value: average.toStringAsFixed(1),
                unit: 'Mbps'),
            MetricTile(
                label: 'Runs',
                value: '${controller.history.length}',
                unit: 'tests'),
          ]),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.result, required this.theme});

  final SpeedResult result;
  final dynamic theme;

  @override
  Widget build(BuildContext context) {
    return BlazeCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(14)),
              child: Icon(Icons.speed_rounded, color: theme.primary)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.quality,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('${_date(result.timestamp)}  •  ${result.server}',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.40), fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${result.download.toStringAsFixed(1)} Mbps',
                  style: TextStyle(
                      color: theme.secondary, fontWeight: FontWeight.w900)),
              Text('${result.ping.toStringAsFixed(0)} ms ping',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.40), fontSize: 10)),
            ],
          ),
          IconButton(
              onPressed: () => Share.share(
                  'Blaze result — ${result.download.toStringAsFixed(1)} Mbps down, ${result.upload.toStringAsFixed(1)} Mbps up, ${result.ping.toStringAsFixed(0)} ms ping.'),
              icon: const Icon(Icons.ios_share_rounded, size: 18)),
        ],
      ),
    );
  }

  String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
