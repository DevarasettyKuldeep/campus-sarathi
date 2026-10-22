import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'models/academic_models.dart';
import 'repositories/academic_store.dart';
import 'widgets/manual_editors.dart';
import 'data/local/academic_database.dart';
import 'screens/local_consent_screen.dart';
import 'features/auth/account_workspaces.dart';
import 'features/auth/auth_api.dart';
import 'features/auth/auth_configuration.dart';
import 'features/auth/google_identity.dart';
import 'features/auth/session_controller.dart';
import 'features/auth/session_gate.dart';
import 'features/auth/session_vault.dart';
import 'features/profile/profile_editor.dart';
import 'features/assistant/assistant_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CampusSarathiApp(enableAssistant: true));
}

class CampusSarathiApp extends StatefulWidget {
  const CampusSarathiApp({
    super.key,
    this.store,
    this.configuration,
    this.requireAuthentication = kReleaseMode,
    this.enableAssistant = false,
  });
  final AcademicStore? store;
  final AuthConfiguration? configuration;
  final bool requireAuthentication;
  final bool enableAssistant;

  @override
  State<CampusSarathiApp> createState() => _CampusSarathiAppState();
}

class _CampusSarathiAppState extends State<CampusSarathiApp> {
  AcademicStore? _store;
  Future<void>? _initialization;
  SessionController? _session;
  AccountWorkspaces? _workspaces;
  String? _configurationError;

  @override
  void initState() {
    super.initState();
    AuthConfiguration? configuration;
    try {
      configuration = widget.configuration ?? AuthConfiguration.fromDefines();
    } catch (_) {
      _configurationError = 'Sign-in configuration is invalid in this build.';
      return;
    }
    if (configuration == null && widget.requireAuthentication) {
      _configurationError =
          'Sign-in is not configured in this build. Contact the developer for a configured build.';
      return;
    }
    if (configuration != null) {
      final workspaces = AccountWorkspaces(
        createStore: (accountId) => AcademicStore(
          database: AcademicDatabase.forAccount(
            accountId,
            namespace: configuration!.storageNamespace,
          ),
        ),
      );
      _workspaces = workspaces;
      _session = SessionController(
        api: HttpAuthApi(baseUrl: configuration.baseUrl),
        vault: SecureSessionVault(server: configuration.baseUrl),
        identity: GoogleStudentIdentity(
          serverClientId: configuration.serverClientId,
        ),
        eraseAccountWorkspace: workspaces.erase,
      );
    } else {
      // Explicit debug/test workspace only; release cannot fall back to it.
      _store =
          widget.store ?? AcademicStore(database: AcademicDatabase.onDevice());
      _initialization = _store!.initialize();
    }
  }

  @override
  void dispose() {
    _session?.dispose();
    final workspaces = _workspaces;
    if (workspaces != null) unawaited(workspaces.close());
    if (widget.store == null && _store != null) {
      unawaited(_store!.close());
      _store!.dispose();
    }
    super.dispose();
  }

  Widget _home() {
    if (_configurationError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Campus Sārathi')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_configurationError!),
          ),
        ),
      );
    }
    final session = _session;
    if (session != null) {
      return SessionGate(
        controller: session,
        workspaces: _workspaces!,
        homeBuilder: (context, store, account, controller) => CampusHome(
          key: ValueKey(account.id),
          store: store,
          session: controller,
          enableAssistant: widget.enableAssistant,
        ),
      );
    }
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Could not open local storage. Your records have not been erased.',
                    ),
                    FilledButton(
                      onPressed: () => setState(
                        () => _initialization = _store!.initialize(),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return AnimatedBuilder(
          animation: _store!,
          builder: (context, _) => _store!.hasConsent
              ? CampusHome(store: _store!, enableAssistant: widget.enableAssistant)
              : LocalConsentScreen(store: _store!),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Campus Sārathi',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff14532d)),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xfff7f8f5),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
    ),
    home: _home(),
  );
}

class CampusHome extends StatefulWidget {
  const CampusHome({
    super.key,
    required this.store,
    this.session,
    this.enableAssistant = false,
  });
  final AcademicStore store;
  final SessionController? session;
  final bool enableAssistant;

  @override
  State<CampusHome> createState() => _CampusHomeState();
}

class _CampusHomeState extends State<CampusHome> {
  int _tab = 0;
  final _titles = const ['Today', 'Academic', 'Assistant', 'Profile'];

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.store.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final body = switch (_tab) {
      0 => Dashboard(store: widget.store),
      1 => AcademicScreen(store: widget.store),
      2 => widget.enableAssistant
          ? AssistantScreen(store: widget.store, session: widget.session)
          : const _EmptyState(
              icon: Icons.auto_awesome_outlined,
              text:
                  'Your academic assistant is not available yet. You can manage your records in Academic.',
            ),
      _ => ProfileScreen(store: widget.store, session: widget.session),
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_tab],
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (widget.session?.phase == SessionPhase.offline)
              MaterialBanner(
                content: const Text(
                  'Offline account: records stay on this device.',
                ),
                actions: [
                  TextButton(
                    onPressed: widget.session!.busy
                        ? null
                        : widget.session!.signIn,
                    child: const Text('Reconnect'),
                  ),
                ],
              ),
            Expanded(child: body),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Academic',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Assistant',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class Dashboard extends StatelessWidget {
  const Dashboard({super.key, required this.store});
  final AcademicStore store;

  @override
  Widget build(BuildContext context) {
    final pending = store.assignments
        .where((a) => a.status == AssignmentStatus.pending)
        .toList();
    final todayClasses = store.classes
        .where((item) => item.day == DateTime.now().weekday)
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
      children: [
        Text(
          _greeting(),
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text('Your academic day, in one place.'),
        const SizedBox(height: 20),
        _InfoCard(
          icon: Icons.lightbulb_outline,
          title: 'Next saved deadline',
          child: Text(
            _priorityText(pending),
            style: const TextStyle(height: 1.45),
          ),
        ),
        const SizedBox(height: 14),
        _SectionHeader(title: "Today's classes", icon: Icons.schedule),
        if (todayClasses.isEmpty)
          const _EmptyState(
            icon: Icons.event_available_outlined,
            text: 'No classes saved for today.',
          )
        else
          ...todayClasses.map(
            (item) => Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.menu_book_outlined),
                ),
                title: Text(item.subject),
                subtitle: Text(
                  '${_time(item.startTime)}–${_time(item.endTime)} · ${item.room}',
                ),
              ),
            ),
          ),
        const SizedBox(height: 14),
        _SectionHeader(
          title: 'Open assignments',
          icon: Icons.assignment_outlined,
        ),
        if (pending.isEmpty)
          const _EmptyState(
            icon: Icons.task_alt,
            text: 'Nothing pending. Add work from Academic.',
          )
        else
          ...pending
              .take(3)
              .map(
                (item) => Card(
                  child: CheckboxListTile(
                    value: false,
                    onChanged: store.busy
                        ? null
                        : (_) => _toggleAssignment(context, store, item.id),
                    title: Text(item.title),
                    subtitle: Text(
                      '${item.subject} · due ${_date(item.dueDate)}',
                    ),
                  ),
                ),
              ),
      ],
    );
  }
}

class AcademicScreen extends StatelessWidget {
  const AcademicScreen({super.key, required this.store});
  final AcademicStore store;

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    child: Column(
      children: [
        const TabBar(
          tabs: [
            Tab(text: 'Assignments'),
            Tab(text: 'Timetable'),
            Tab(text: 'Attendance'),
          ],
        ),
        Expanded(
          child: TabBarView(
            children: [
              _AssignmentsTab(store: store),
              _TimetableTab(store: store),
              _AttendanceTab(store: store),
            ],
          ),
        ),
      ],
    ),
  );
}

class _AssignmentsTab extends StatelessWidget {
  const _AssignmentsTab({required this.store});
  final AcademicStore store;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: store.assignments.isEmpty
        ? const _EmptyState(
            icon: Icons.assignment_outlined,
            text: 'Add your first assignment to start planning.',
          )
        : ListView(
            padding: const EdgeInsets.all(16),
            children: store.assignments
                .map(
                  (item) => Card(
                    child: CheckboxListTile(
                      value: item.status == AssignmentStatus.complete,
                      onChanged: store.busy
                          ? null
                          : (_) => _toggleAssignment(context, store, item.id),
                      title: Text(item.title),
                      subtitle: Text(
                        '${item.subject} · due ${_date(item.dueDate)}',
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () =>
          showManualEditor(context, store, ManualEntryType.assignment),
      icon: const Icon(Icons.add),
      label: const Text('Assignment'),
    ),
  );
}

class _TimetableTab extends StatelessWidget {
  const _TimetableTab({required this.store});
  final AcademicStore store;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: store.classes.isEmpty
        ? const _EmptyState(
            icon: Icons.calendar_month_outlined,
            text: 'Your timetable is empty. Add a recurring class.',
          )
        : ListView(
            padding: const EdgeInsets.all(16),
            children: store.classes
                .map(
                  (item) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.menu_book_outlined),
                      title: Text(item.subject),
                      subtitle: Text(
                        '${_weekday(item.day)} · ${_time(item.startTime)}–${_time(item.endTime)} · ${item.room}',
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () =>
          showManualEditor(context, store, ManualEntryType.timetable),
      icon: const Icon(Icons.add),
      label: const Text('Class'),
    ),
  );
}

class _AttendanceTab extends StatelessWidget {
  const _AttendanceTab({required this.store});
  final AcademicStore store;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: store.attendance.isEmpty
        ? const _EmptyState(
            icon: Icons.bar_chart_outlined,
            text: 'Save attendance to see risk-aware insights.',
          )
        : ListView(
            padding: const EdgeInsets.all(16),
            children: store.attendance.map((item) {
              final atRisk = item.isBelowMinimum == true;
              return Card(
                child: ListTile(
                  title: Text(item.subject),
                  subtitle: Text(
                    '${item.attended}/${item.total} classes · ${item.sourceLabel}\nUpdated ${_date(item.updatedAt)}${item.minimumPercentage == null ? ' · minimum not set' : ' · minimum ${item.minimumPercentage}%'}',
                  ),
                  trailing: Text(
                    item.percentage == null
                        ? 'No classes yet'
                        : '${item.percentage!.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: item.isBelowMinimum == null
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : atRisk
                          ? Colors.red.shade700
                          : Colors.green.shade700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () =>
          showManualEditor(context, store, ManualEntryType.attendance),
      icon: const Icon(Icons.edit_outlined),
      label: const Text('Attendance'),
    ),
  );
}


class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.store, this.session});
  final AcademicStore store;
  final SessionController? session;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const CircleAvatar(radius: 32, child: Icon(Icons.person, size: 34)),
      const SizedBox(height: 14),
      Text(
        session?.account?.displayName ?? 'Set up your academic profile',
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      Text(
        session?.account == null
            ? 'Your records are stored on this device. This development build has no signed-in account or cloud sync.'
            : '${session!.account!.email}\nYour account records stay on this device. Cloud academic sync is not connected yet.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 28),
      ListTile(
        leading: const Icon(Icons.school_outlined),
        title: Text(store.profile?.programme ?? 'Add semester profile'),
        subtitle: Text(
          store.profile == null
              ? 'Programme, semester and dates • device only'
              : 'Semester ${store.profile!.semesterNumber}\n${store.profile!.semesterStart} to ${store.profile!.semesterEnd}\nStudent-entered • device only',
        ),
        trailing: const Icon(Icons.edit_outlined),
        onTap: store.busy
            ? null
            : () => Navigator.of(context).push<void>(
                MaterialPageRoute(builder: (_) => ProfileEditor(store: store)),
              ),
      ),
      ListTile(
        leading: Icon(Icons.verified_user_outlined),
        title: const Text('Local privacy notice'),
        subtitle: const Text(
          'Review what is stored and how to withdraw consent.',
        ),
        onTap: () => showLocalPrivacyNotice(context),
      ),
      ListTile(
        leading: Icon(Icons.cloud_off_outlined),
        title: const Text('Local academic records'),
        subtitle: Text(
          session == null
              ? 'Test locally. Server authentication is not configured in this build.'
              : 'Account-specific cache. No automatic upload of local records.',
        ),
      ),
      if (session != null) ...[
        ListTile(
          leading: const Icon(Icons.cloud_sync_outlined),
          title: const Text('Cloud academic processing notice'),
          subtitle: const Text(
            'Review server data processing and privacy terms.',
          ),
          onTap: () => showCloudPrivacyNotice(context),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: store.busy || session!.busy
              ? null
              : () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Sign out and clear this account?'),
                      content: const Text(
                        'This clears cached academic records for this account. These records have not been synced. Sign out only when you no longer need the local copies.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Keep account open'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Sign out'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) await session!.signOut();
                },
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: store.busy || session!.busy
              ? null
              : () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Permanently delete account?'),
                      content: const Text(
                        'This deletes your student account, profile, sessions and cloud data from the server, and completely erases local records from this device. There is no undo.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete account'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    final success = await session!.deleteAccount();
                    if (!success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Server account deletion could not be confirmed.',
                          ),
                        ),
                      );
                    }
                  }
                },
          icon: const Icon(Icons.person_remove_outlined),
          label: const Text('Delete server account'),
        ),
      ],
      const SizedBox(height: 20),
      OutlinedButton.icon(
        onPressed: store.busy
            ? null
            : () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Erase local records?'),
                    content: const Text(
                      'This permanently removes your semester profile, assignments, timetable and attendance from this app, and withdraws local processing consent. There is no undo.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Keep records'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Erase records'),
                      ),
                    ],
                  ),
                );
                if (confirmed != true) return;
                try {
                  await store.eraseLocalData();
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Could not erase local records. Please retry.',
                        ),
                      ),
                    );
                  }
                }
              },
        icon: const Icon(Icons.delete_outline),
        label: const Text('Erase local records'),
      ),
    ],
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.child,
  });
  final IconData icon;
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.primaryContainer,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 38, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

Future<void> _toggleAssignment(
  BuildContext context,
  AcademicStore store,
  String id,
) async {
  try {
    await store.toggleAssignment(id);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update the assignment. Please try again.'),
        ),
      );
    }
  }
}

String _greeting() {
  final hour = DateTime.now().hour;
  return hour < 12
      ? 'Good morning'
      : hour < 17
      ? 'Good afternoon'
      : 'Good evening';
}

String _priorityText(List<Assignment> pending) => pending.isEmpty
    ? 'Add your assignments to see the nearest pending deadline here.'
    : '${pending.first.title} (${pending.first.subject}) has your nearest saved deadline. Review it in Academic.';
String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')} ${_month(value.month)}';
String _month(int month) => const [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
][month - 1];
String _weekday(int day) =>
    const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day - 1];
String _time(TimeOfDayValue value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
