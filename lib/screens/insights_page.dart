
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/todo.dart';
import '../services/notification_service.dart';
import '../painters/pie_painter.dart';
import '../utils/todo_utils.dart';
import '../widgets/common_widgets.dart';
import '../widgets/video_background.dart';

class InsightsPage extends StatelessWidget {
  final List<Todo> todos;

  const InsightsPage({
    super.key,
    required this.todos,
  });

  int completedOn(DateTime date) {
    return todos.where((todo) {
      final d = todo.actualCompletionDate;

      return todo.done &&
          d != null &&
          d.year == date.year &&
          d.month == date.month &&
          d.day == date.day;
    }).length;
  }

  int priorityCount(Priority priority) {
    return todos.where((todo) {
      return todo.priority == priority;
    }).length;
  }

  int categoryCount(Category category) {
    return todos.where((todo) {
      return todo.category == category;
    }).length;
  }

  int get completed {
    return todos.where((todo) => todo.done).length;
  }

  int get pending {
    return todos.where((todo) => !todo.done).length;
  }

  int get overdue {
    return todos.where((todo) {
      return !todo.done &&
          todo.completionDate != null &&
          daysLeft(todo.completionDate!) < 0;
    }).length;
  }

  int get today {
    return todos.where((todo) {
      return !todo.done &&
          todo.completionDate != null &&
          daysLeft(todo.completionDate!) == 0;
    }).length;
  }

  int get completedToday => completedOn(DateTime.now());

  int get totalTrackedSeconds {
    return todos.fold<int>(
      0,
      (total, todo) => total + todo.elapsedWorkSeconds,
    );
  }

  int get streak {
    var date = DateTime.now();
    var count = 0;

    while (completedOn(date) > 0) {
      count++;
      date = date.subtract(const Duration(days: 1));
    }

    return count;
  }

  String get achievementMessage {
    if (todos.isEmpty) {
      return 'Your journey starts with one small task. '
          'Add a task and take your first step!';
    }

    if (completedToday == 0 && totalTrackedSeconds == 0) {
      return 'Every achievement starts somewhere. '
          'Choose a task and begin building your momentum.';
    }

    if (completedToday == 0) {
      return 'You have invested time in your tasks. '
          'Keep going — consistent effort matters!';
    }

    if (completedToday == 1) {
      return 'One task completed today! Celebrate that progress '
          'and keep moving forward.';
    }

    return '$completedToday tasks completed today! '
        'Your consistency is turning effort into achievement.';
  }

  int statColumns(double width) {
    if (width < 420) return 2;
    if (width < 700) return 3;
    return 5;
  }

  int detailColumns(double width) {
    if (width < 600) return 1;
    if (width < 950) return 2;
    if (width < 1350) return 3;
    return 4;
  }

  double horizontalPadding(double width) {
    if (width < 500) return 8;
    if (width < 900) return 12;
    return 18;
  }

  double gridGap(double width) {
    if (width < 500) return 7;
    if (width < 900) return 10;
    return 14;
  }

  double detailRatio(double width, int columns) {
    if (columns == 1) return 1.30;
    if (width < 950) return 0.95;
    if (width < 1350) return 1.0;
    return 1.15;
  }

  String formatDuration(int seconds) {
    final safeSeconds = seconds < 0 ? 0 : seconds;
    final hours = safeSeconds ~/ 3600;
    final minutes = (safeSeconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }

    if (minutes > 0) {
      return '${minutes}m';
    }

    return '${safeSeconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final statCount = statColumns(width);
    final detailCount = detailColumns(width);
    final padding = horizontalPadding(width);
    final gap = gridGap(width);

    return VideoBackground(
      overlayColor: Colors.transparent,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text(
            'Insights',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          foregroundColor: Colors.white,
        ),
        body: SafeArea(
          child: CustomScrollView(
            key: const PageStorageKey('insights_scroll'),
            primary: false,
            physics: const AlwaysScrollableScrollPhysics(
              parent: ClampingScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  padding,
                  10,
                  padding,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: _achievementCard(),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  padding,
                  gap,
                  padding,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: DailyNotificationSettingsCard(
                    summaryBody:
                        '$completedToday tasks completed today. '
                        'Focus time: ${formatDuration(totalTrackedSeconds)}. '
                        '$achievementMessage',
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(height: gap),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  padding,
                  0,
                  padding,
                  0,
                ),
                sliver: SliverGrid(
                  delegate: SliverChildListDelegate([
                    statCard(
                      'Completed',
                      '$completed',
                      Icons.check_circle,
                    ),
                    statCard(
                      'Pending',
                      '$pending',
                      Icons.pending,
                    ),
                    statCard(
                      'Overdue',
                      '$overdue',
                      Icons.warning,
                    ),
                    statCard(
                      'Due Today',
                      '$today',
                      Icons.today,
                    ),
                    statCard(
                      'Streak',
                      '$streak days',
                      Icons.local_fire_department,
                    ),
                  ]),
                  gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: statCount,
                    crossAxisSpacing: gap,
                    mainAxisSpacing: gap,
                    childAspectRatio:
                        width < 500 ? 1.25 : 1.55,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(height: gap),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  padding,
                  0,
                  padding,
                  30,
                ),
                sliver: SliverGrid(
                  delegate: SliverChildListDelegate([
                    _progressCard(width),
                    _priorityCard(width),
                    _categoryCard(width),
                    _weeklyCard(width),
                  ]),
                  gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: detailCount,
                    crossAxisSpacing: gap,
                    mainAxisSpacing: gap,
                    childAspectRatio: detailRatio(
                      width,
                      detailCount,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _achievementCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE9E4FF),
            Color(0xFFDDF2FF),
            Color(0xFFFFE5F0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFF7255C7),
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Daily Achievements',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF332C55),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Small steps create big progress',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF655E80),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _achievementMetric(
                  icon: Icons.task_alt_rounded,
                  label: 'Done today',
                  value: '$completedToday',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _achievementMetric(
                  icon: Icons.timer_rounded,
                  label: 'Focus time',
                  value: formatDuration(totalTrackedSeconds),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _achievementMetric(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Streak',
                  value: '$streak days',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  size: 19,
                  color: Color(0xFFCB6494),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    achievementMessage,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF443B61),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _achievementMetric({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF7255C7),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF332C55),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF655E80),
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressCard(double width) {
    return _whiteCard(
      child: Column(
        children: [
          const Text(
            'Progress',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: CustomPaint(
              painter: PiePainter(
                completed.toDouble(),
                pending.toDouble(),
              ),
              child: Center(
                child: Text(
                  todos.isEmpty
                      ? '0%'
                      : '${(completed / todos.length * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priorityCard(double width) {
    return _whiteCard(
      child: Column(
        children: [
          const Text(
            'Priority',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...Priority.values.map((priority) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 3,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: priorityColor(priority),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      priorityName(priority),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${priorityCount(priority)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _categoryCard(double width) {
    return _whiteCard(
      child: Column(
        children: [
          const Text(
            'Categories',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...Category.values.map((category) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 2,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.category,
                    size: 15,
                    color: Color.fromARGB(255, 20, 4, 163),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      categoryName(category),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${categoryCount(category)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _weeklyCard(double width) {
    final now = DateTime.now();

    final values = List.generate(7, (index) {
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: 6 - index));

      return completedOn(date);
    });

    final max = values.fold<int>(
      1,
      (a, b) => a > b ? a : b,
    );

    return _whiteCard(
      child: Column(
        children: [
          const Text(
            'Weekly Productivity',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (index) {
                final value = values[index];
                final barHeight = 70.0 * value / max;

                final date = DateTime(
                  now.year,
                  now.month,
                  now.day,
                ).subtract(Duration(days: 6 - index));

                return Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$value',
                        style: const TextStyle(
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        width: width < 500 ? 9 : 12,
                        height: barHeight < 4 ? 4 : barHeight,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color.fromARGB(255, 22, 1, 112),
                              Color.fromARGB(255, 57, 114, 221),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _dayName(date),
                        style: const TextStyle(
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  String _dayName(DateTime date) {
    const names = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return names[date.weekday - 1];
  }

  Widget _whiteCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(1, 255, 255, 255)
            .withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color.fromARGB(3, 255, 255, 255)
              .withValues(alpha: 0.7),
        ),
      ),
      child: child,
    );
  }
}


class DailyNotificationSettingsCard extends StatefulWidget {
  final String summaryBody;

  const DailyNotificationSettingsCard({
    super.key,
    required this.summaryBody,
  });

  @override
  State<DailyNotificationSettingsCard> createState() =>
      _DailyNotificationSettingsCardState();
}

class _DailyNotificationSettingsCardState
    extends State<DailyNotificationSettingsCard> {
  static const String _enabledKey = 'daily_summary_enabled';
  static const String _hourKey = 'daily_summary_hour';
  static const String _minuteKey = 'daily_summary_minute';

  bool _enabled = true;
  int _hour = 17;
  int _minute = 45;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (!mounted) return;

      setState(() {
        _enabled = prefs.getBool(_enabledKey) ?? true;
        _hour = prefs.getInt(_hourKey) ?? 17;
        _minute = prefs.getInt(_minuteKey) ?? 45;
        _isLoading = false;
      });

      if (_enabled) {
        await _scheduleNotification();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint('Could not load notification settings: $error');
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_enabledKey, _enabled);
    await prefs.setInt(_hourKey, _hour);
    await prefs.setInt(_minuteKey, _minute);
  }

  Future<void> _scheduleNotification() async {
    await NotificationService.instance.scheduleDailySummary(
      body: widget.summaryBody,
      hour: _hour,
      minute: _minute,
    );
  }

  String _formatTime(BuildContext context) {
    return TimeOfDay(hour: _hour, minute: _minute)
        .format(context);
  }

  Future<void> _chooseTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
      helpText: 'Choose your daily summary time',
    );

    if (selectedTime == null || !mounted) return;

    setState(() {
      _hour = selectedTime.hour;
      _minute = selectedTime.minute;
      _isSaving = true;
    });

    try {
      await _saveSettings();

      if (_enabled) {
        await _scheduleNotification();
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _enabled
                ? 'Daily summary set for ${_formatTime(context)}.'
                : 'Preferred time saved. Notifications are off.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not update the notification. Please check notification permissions.',
          ),
        ),
      );
      debugPrint('Could not schedule daily summary: $error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _enabled = value;
      _isSaving = true;
    });

    try {
      await _saveSettings();

      if (_enabled) {
        await _scheduleNotification();
      } else {
        await NotificationService.instance.cancelDailySummary();
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _enabled
                ? 'Daily achievement notifications enabled.'
                : 'Daily achievement notifications disabled.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not update notification settings. Please check notification permissions.',
          ),
        ),
      );
      debugPrint('Could not update notification setting: $error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFDCD5F5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: _isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(108, 233, 228, 255),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: Color.fromARGB(101, 113, 85, 199),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily Notification Settings',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF332C55),
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'A gentle reminder to celebrate your progress',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF655E80),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _enabled,
                      onChanged: _isSaving
                          ? null
                          : _toggleNotifications,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F5FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        color: Color(0xFF7255C7),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your preferred time',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatTime(context),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF7255C7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: _isSaving ? null : _chooseTime,
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Default: 5:45 PM, shortly after the 5:30 PM office finish. '
                  'Choose any time that fits your routine.',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.72),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                if (_isSaving) ...[
                  const SizedBox(height: 10),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
    );
  }
}
