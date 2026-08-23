import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/blaze_theme.dart';
import '../models/speed_result.dart';
import '../services/speed_test_service.dart';

class BlazeController extends ChangeNotifier {
  BlazeController({SpeedTestService? speedTestService})
      : _speedTestService = speedTestService ?? SpeedTestService();

  static const _activeThemeKey = 'active_theme';
  static const _savedThemesKey = 'saved_themes';
  static const _historyKey = 'history';

  final SpeedTestService _speedTestService;
  SharedPreferences? _preferences;
  BlazeTheme activeTheme = BlazeTheme.presets.first;
  List<BlazeTheme> savedThemes = [];
  List<SpeedResult> history = [];
  SpeedResult? latestResult;
  TestPhase phase = TestPhase.idle;
  double gaugeValue = 0;
  double liveSpeed = 0;
  double peakSpeed = 0;
  String? errorMessage;
  DateTime? _lastProgressNotify;

  double get dialMax {
    final observed = math.max(liveSpeed, peakSpeed);
    if (observed <= 0) return 25;
    return _niceCeiling(math.max(observed * 1.25, 1));
  }

  bool get isTesting =>
      phase != TestPhase.idle &&
      phase != TestPhase.finished &&
      phase != TestPhase.error;

  Future<void> hydrate() async {
    _preferences = await SharedPreferences.getInstance();
    final activeId = _preferences?.getString(_activeThemeKey);
    final saved = _preferences?.getStringList(_savedThemesKey) ?? [];
    savedThemes = saved.map(_decodeTheme).whereType<BlazeTheme>().toList();
    activeTheme = _findTheme(activeId) ?? activeTheme;
    final storedHistory = _preferences?.getStringList(_historyKey) ?? [];
    history =
        storedHistory.map(_decodeResult).whereType<SpeedResult>().toList();
    latestResult = history.isEmpty ? null : history.first;
    notifyListeners();
  }

  BlazeTheme? _decodeTheme(String item) {
    try {
      return BlazeTheme.fromJson(jsonDecode(item) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  SpeedResult? _decodeResult(String item) {
    try {
      return SpeedResult.fromJson(jsonDecode(item) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  BlazeTheme? _findTheme(String? id) {
    if (id == null) return null;
    for (final theme in [...BlazeTheme.presets, ...savedThemes]) {
      if (theme.id == id) return theme;
    }
    return null;
  }

  void selectTheme(BlazeTheme theme) {
    activeTheme = theme;
    _preferences?.setString(_activeThemeKey, theme.id);
    notifyListeners();
  }

  void saveTheme(BlazeTheme theme) {
    final saved = theme.copyWith(
      id: 'saved-${DateTime.now().microsecondsSinceEpoch}',
      subtitle: 'Your custom build',
    );
    savedThemes = [saved, ...savedThemes];
    selectTheme(saved);
    _persistThemes();
  }

  void deleteTheme(BlazeTheme theme) {
    savedThemes = savedThemes.where((item) => item.id != theme.id).toList();
    if (activeTheme.id == theme.id) {
      selectTheme(BlazeTheme.presets.first);
    }
    _persistThemes();
    notifyListeners();
  }

  Future<void> startTest() async {
    if (isTesting) return;
    errorMessage = null;
    gaugeValue = 0;
    liveSpeed = 0;
    peakSpeed = 0;
    _lastProgressNotify = null;
    latestResult = null;
    phase = TestPhase.connecting;
    notifyListeners();
    try {
      final result = await _speedTestService.run(
        onPhase: (nextPhase) {
          phase = nextPhase;
          gaugeValue = 0;
          if (nextPhase == TestPhase.connecting ||
              nextPhase == TestPhase.ping ||
              nextPhase == TestPhase.download ||
              nextPhase == TestPhase.upload) {
            liveSpeed = 0;
            peakSpeed = 0;
          }
          notifyListeners();
        },
        onProgress: (progress) {
          gaugeValue = progress.fraction;
          if (progress.speedMBps > 0) {
            liveSpeed = progress.speedMBps;
            peakSpeed = math.max(peakSpeed, progress.speedMBps);
          }
          final now = DateTime.now();
          if (progress.fraction < 1 &&
              _lastProgressNotify != null &&
              now.difference(_lastProgressNotify!).inMilliseconds < 42) {
            return;
          }
          _lastProgressNotify = now;
          notifyListeners();
        },
      );
      latestResult = result;
      liveSpeed = result.download;
      peakSpeed = math.max(peakSpeed, result.download);
      history = [result, ...history].take(20).toList();
      phase = TestPhase.finished;
      _persistHistory();
      notifyListeners();
    } catch (error) {
      phase = TestPhase.error;
      errorMessage = error is SpeedTestException
          ? error.message
          : 'The test could not finish. Check your connection and try again.';
      notifyListeners();
    }
  }

  void resetTest() {
    phase = TestPhase.idle;
    gaugeValue = 0;
    liveSpeed = 0;
    peakSpeed = 0;
    errorMessage = null;
    notifyListeners();
  }

  double _niceCeiling(double value) {
    final magnitude = math
        .pow(
          10,
          (math.log(value) / math.log(10)).floor(),
        )
        .toDouble();
    final normalized = value / magnitude;
    final multiplier = normalized <= 1
        ? 1
        : normalized <= 2
            ? 2
            : normalized <= 5
                ? 5
                : 10;
    return multiplier * magnitude;
  }

  Future<void> _persistThemes() async {
    await _preferences?.setStringList(
      _savedThemesKey,
      savedThemes.map((theme) => jsonEncode(theme.toJson())).toList(),
    );
  }

  Future<void> _persistHistory() async {
    await _preferences?.setStringList(
      _historyKey,
      history.map((result) => jsonEncode(result.toJson())).toList(),
    );
  }
}
