import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Performance monitoring widget that tracks FPS
/// 
/// Displays current FPS in debug mode and logs warnings
/// when FPS drops below 30 FPS threshold.
/// 
/// Requirement: 9.1 - Maintain at least 30 FPS during scrolling
class PerformanceMonitor extends StatefulWidget {
  final Widget child;
  final bool showOverlay;

  const PerformanceMonitor({
    super.key,
    required this.child,
    this.showOverlay = false,
  });

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor> {
  double _currentFps = 60.0;
  final List<Duration> _frameTimes = [];
  static const int _sampleSize = 60; // Sample last 60 frames
  static const double _targetFps = 30.0;

  @override
  void initState() {
    super.initState();
    _startMonitoring();
  }

  void _startMonitoring() {
    SchedulerBinding.instance.addTimingsCallback(_onFrameTiming);
  }

  void _onFrameTiming(List<FrameTiming> timings) {
    if (!mounted) return;

    for (final timing in timings) {
      final frameDuration = timing.totalSpan;
      _frameTimes.add(frameDuration);

      // Keep only recent samples
      if (_frameTimes.length > _sampleSize) {
        _frameTimes.removeAt(0);
      }
    }

    // Calculate average FPS
    if (_frameTimes.isNotEmpty) {
      final avgDuration = _frameTimes.reduce((a, b) => a + b) ~/ _frameTimes.length;
      final fps = Duration.microsecondsPerSecond / avgDuration.inMicroseconds;

      // Use post-frame callback to avoid calling setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _currentFps = fps;
          });
        }
      });

      // Log warning if FPS drops below target
      if (fps < _targetFps) {
        debugPrint('⚠️ Performance warning: FPS dropped to ${fps.toStringAsFixed(1)}');
      }
    }
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onFrameTiming);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.showOverlay)
          Positioned(
            top: 50,
            right: 16,
            child: _buildFpsOverlay(),
          ),
      ],
    );
  }

  Widget _buildFpsOverlay() {
    final color = _currentFps >= _targetFps ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '${_currentFps.toStringAsFixed(1)} FPS',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
