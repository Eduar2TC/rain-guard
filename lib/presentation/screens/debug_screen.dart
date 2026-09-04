import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rain_guard/application/state/debug_state_provider.dart';
import 'package:rain_guard/core/logging/app_logger.dart';

class DebugScreen extends ConsumerStatefulWidget {
  const DebugScreen({super.key});

  @override
  ConsumerState<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends ConsumerState<DebugScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(debugStateProvider.notifier).startAutoRefresh();
    });
  }

  @override
  void dispose() {
    ref.read(debugStateProvider.notifier).stopAutoRefresh();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final debugState = ref.watch(debugStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Console'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              ref.read(debugStateProvider.notifier).clearLogs();
            },
            tooltip: 'Clear logs',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(debugStateProvider.notifier).refreshLogs();
              ref.read(debugStateProvider.notifier).refreshSystemInfo();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // System Info Card
          _buildSystemInfoCard(debugState),

          const Divider(height: 1),

          // Logs
          Expanded(
            child: _buildLogsList(debugState.logs),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemInfoCard(DebugState debugState) {
    final info = debugState.systemInfo;

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Info',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildInfoChip('Monitoring', info['isMonitoring']?.toString() ?? '--'),
                _buildInfoChip('Risk State', info['riskState']?.toString() ?? '--'),
                _buildInfoChip('ETA', info['etaMinutes'] != null ? '${info['etaMinutes']} min' : '--'),
                _buildInfoChip('Confidence', info['confidence']?.toString() ?? '--'),
                _buildInfoChip('Battery', info['batteryLevel'] != null ? '${info['batteryLevel']}%' : '--'),
                _buildInfoChip('Network', info['weatherNetwork']?.toString() ?? '--'),
                _buildInfoChip('Accuracy', info['accuracy'] != null ? '${info['accuracy']}m' : '--'),
                _buildInfoChip('Speed', info['speed'] != null ? '${info['speed']} m/s' : '--'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsList(List<LogEntry> logs) {
    if (logs.isEmpty) {
      return const Center(
        child: Text('No logs yet'),
      );
    }

    return ListView.builder(
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[logs.length - 1 - index]; // Reverse order
        return _buildLogEntry(log);
      },
    );
  }

  Widget _buildLogEntry(LogEntry log) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp
          Text(
            '${log.timestamp.hour.toString().padLeft(2, '0')}:'
            '${log.timestamp.minute.toString().padLeft(2, '0')}:'
            '${log.timestamp.second.toString().padLeft(2, '0')}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
          const SizedBox(width: 8),

          // Level badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: _getLevelColor(log.level),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              log.level.name,
              style: const TextStyle(fontSize: 9, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),

          // Tag
          Text(
            log.tag,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _getTagColor(log.tag),
            ),
          ),
          const SizedBox(width: 8),

          // Message
          Expanded(
            child: Text(
              log.message,
              style: const TextStyle(fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
    }
  }

  Color _getTagColor(String tag) {
    switch (tag) {
      case LogTags.location:
        return Colors.green;
      case LogTags.weather:
        return Colors.blue;
      case LogTags.prediction:
        return Colors.purple;
      case LogTags.alert:
        return Colors.red;
      case LogTags.monitoring:
        return Colors.teal;
      case LogTags.bubble:
        return Colors.orange;
      case LogTags.battery:
        return Colors.amber;
      case LogTags.notification:
        return Colors.indigo;
      case LogTags.permission:
        return Colors.pink;
      case LogTags.network:
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }
}
