import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wise_live_sdk/wise_live_sdk.dart';

void main() => runApp(const MaterialApp(title: 'Wise SDK sample', home: SamplePage()));

class SamplePage extends StatefulWidget {
  const SamplePage({super.key});

  @override
  State<SamplePage> createState() => _SamplePageState();
}

class _SamplePageState extends State<SamplePage> {
  // Values with a key are saved on the device.
  final _namespace = _Field('Namespace', 'e.g. yourcompany', 'namespace');
  final _classPublicId = _Field('Class public ID', "32-character ID from the class's public link", 'classPublicId');
  final _displayName = _Field('Display name', 'Name shown in the class', null, initial: 'Student');
  final _classId = _Field('Class ID', '24-character class ID', 'classId');
  final _ssoToken = TextEditingController();

  final _log = <String>[];
  StreamSubscription<WiseEvent>? _events;
  bool _ready = false;
  bool _signedIn = false;

  List<_Field> get _fields => [_namespace, _classPublicId, _displayName, _classId];

  @override
  void initState() {
    super.initState();
    _events = WiseLiveSdk.events.listen((e) => _add('${e.type} ${Map.of(e.raw)..remove('type')}'));
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    for (final f in _fields) {
      final key = f.key;
      if (key == null) continue;
      f.controller.text = prefs.getString('wise-sample.$key') ?? '';
      f.controller.addListener(() => prefs.setString('wise-sample.$key', f.text));
    }
    // The SDK keeps the session across launches: no need to sign in again while it exists.
    await _updateSignedIn();
  }

  @override
  void dispose() {
    _events?.cancel();
    super.dispose();
  }

  Future<void> _initialize() => _run('initialize', () async {
        await WiseLiveSdk.initialize(namespace: _namespace.text);
        // Screen share (iOS): App Group and extension bundle ID come from ios/Wise.xcconfig via Info.plist.
        if (Platform.isIOS) await WiseLiveSdk.enableScreenShare();
        _ready = true;
      });

  Future<void> _signIn() => _whenReady('loginUsingSSOToken', () async {
        // Tokens pasted from chat apps often contain line breaks or spaces.
        await WiseLiveSdk.loginUsingSSOToken(_ssoToken.text.replaceAll(RegExp(r'\s'), ''));
        _ssoToken.clear();
        await _updateSignedIn();
      });

  Future<void> _signOut() => _run('logoutSSO', () async {
        await WiseLiveSdk.logoutSSO();
        await _updateSignedIn();
      });

  Future<void> _updateSignedIn() async {
    final signedIn = await WiseLiveSdk.isLoggedIn();
    if (mounted) setState(() => _signedIn = signedIn);
  }

  Future<void> _whenReady(String name, Future<void> Function() action) async {
    if (!_ready) return _add('Tap Initialize first');
    await _run(name, action);
  }

  Future<void> _run(String name, Future<void> Function() action) async {
    try {
      await action();
      _add('$name: ok');
    } on PlatformException catch (e) {
      _add('$name: ${e.message ?? e.code}');
    }
  }

  void _add(String line) {
    if (!mounted) return;
    final now = TimeOfDay.now().format(context);
    setState(() => _log.insert(0, '$now  $line'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wise SDK sample')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            const _Section('Your details (from Wise)'),
            _namespace.build(),
            FilledButton.tonal(onPressed: _initialize, child: const Text('Initialize')),
            const _Section('Join as guest'),
            _classPublicId.build(),
            _displayName.build(),
            FilledButton.tonal(
              onPressed: () => _whenReady('joinMeetingAsGuest',
                  () => WiseLiveSdk.joinMeetingAsGuest(classPublicId: _classPublicId.text, displayName: _displayName.text)),
              child: const Text('Join by public ID'),
            ),
            _Section(_signedIn ? 'Sign in · Signed in ✓' : 'Sign in (once per install)'),
            TextField(
              controller: _ssoToken,
              enabled: !_signedIn,
              minLines: 3,
              maxLines: 5,
              autocorrect: false,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: const InputDecoration(
                labelText: 'SSO token (JWT signed by your backend)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: FilledButton.tonal(onPressed: _signedIn ? null : _signIn, child: const Text('Sign in'))),
              const SizedBox(width: 12),
              Expanded(child: FilledButton.tonal(onPressed: _signedIn ? _signOut : null, child: const Text('Sign out'))),
            ]),
            const _Section('Signed-in user'),
            _classId.build(),
            Row(children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () => _whenReady('joinMeeting', () => WiseLiveSdk.joinMeeting(classId: _classId.text)),
                  child: const Text('Join class'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () => _whenReady('startMeeting', () => WiseLiveSdk.startMeeting(classId: _classId.text)),
                  child: const Text('Start class (teacher)'),
                ),
              ),
            ]),
            const _Section('Events'),
            Container(
              height: 200,
              padding: const EdgeInsets.all(8),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: ListView(
                children: [for (final l in _log) Text(l, style: const TextStyle(fontFamily: 'monospace', fontSize: 11))],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      );
}

class _Field {
  _Field(this.label, this.hint, this.key, {String initial = ''}) : controller = TextEditingController(text: initial);

  final String label;
  final String hint;
  final String? key;
  final TextEditingController controller;

  String get text => controller.text.trim();

  Widget build() => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextField(
          controller: controller,
          autocorrect: false,
          decoration: InputDecoration(labelText: label, hintText: hint, border: const OutlineInputBorder()),
        ),
      );
}
