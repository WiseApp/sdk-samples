import React, { useEffect, useState } from 'react';
import {
  Button,
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import { SafeAreaProvider, SafeAreaView } from 'react-native-safe-area-context';
import AsyncStorage from '@react-native-async-storage/async-storage';
import WiseSDK, { type WiseEvent } from '@wiseapp/react-native-sdk';

// Entered on screen and saved on the device.
type Details = { namespace: string; classId: string; classPublicId: string };
const EMPTY: Details = { namespace: '', classId: '', classPublicId: '' };
const STORAGE_KEY = 'wise-sample-details';

// iOS screen share: the App Group and the broadcast extension's bundle ID, passed in by
// ios/WiseSample/SceneDelegate.swift from Info.plist (set them in ios/Config.local.xcconfig).
type Props = { wiseAppGroup?: string; wiseScreenShareBundleId?: string };

export default function App({ wiseAppGroup, wiseScreenShareBundleId }: Props) {
  const [details, setDetails] = useState<Details>(EMPTY);
  const [ready, setReady] = useState(false);
  const [signedIn, setSignedIn] = useState(false);
  const [ssoToken, setSsoToken] = useState('');
  const [displayName, setDisplayName] = useState('Student');
  const [log, setLog] = useState<string[]>([]);

  const add = (line: string) =>
    setLog(prev =>
      [`${new Date().toLocaleTimeString()}  ${line}`, ...prev].slice(0, 50),
    );

  const run = async (label: string, fn: () => unknown) => {
    try {
      await fn();
      add(`${label}: ok`);
    } catch (e: any) {
      add(`${label}: ${e?.code ?? ''} ${e?.message ?? e}`);
    }
  };

  const set = (key: keyof Details) => (value: string) => {
    const next = { ...details, [key]: value.trim() };
    setDetails(next);
    AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(next)).catch(() => {});
  };

  useEffect(() => {
    const sub = WiseSDK.addListener((event: WiseEvent) =>
      add(JSON.stringify(event)),
    );
    // The SDK keeps the session across launches; no need to sign in again while it exists.
    WiseSDK.isLoggedIn()
      .then(setSignedIn)
      .catch(() => {});
    AsyncStorage.getItem(STORAGE_KEY)
      .then(saved => saved && setDetails({ ...EMPTY, ...JSON.parse(saved) }))
      .catch(() => {});
    return () => sub.remove();
  }, []);

  const initialize = () =>
    run('initialize', async () => {
      await WiseSDK.initialize(details.namespace);
      if (wiseAppGroup && wiseScreenShareBundleId) {
        WiseSDK.enableScreenShare(wiseAppGroup, wiseScreenShareBundleId);
      }
      setReady(true);
    });

  return (
    <SafeAreaProvider>
      <SafeAreaView style={styles.container}>
        <ScrollView
          contentContainerStyle={styles.content}
          keyboardShouldPersistTaps="handled"
        >
          <Text style={styles.title}>Wise SDK sample</Text>

          <Text style={styles.section}>Your details (from Wise)</Text>
          <Field
            label="Namespace"
            placeholder="e.g. yourcompany"
            value={details.namespace}
            onChange={set('namespace')}
          />
          <Button
            title="Initialize"
            disabled={!details.namespace}
            onPress={initialize}
          />

          <Text style={styles.section}>Join as guest</Text>
          <Field
            label="Class public ID"
            placeholder="32-character ID from the class's public link"
            value={details.classPublicId}
            onChange={set('classPublicId')}
          />
          <Field
            label="Display name"
            placeholder="Name shown in the class"
            value={displayName}
            onChange={setDisplayName}
          />
          <Button
            title="Join by public ID"
            disabled={!ready || !details.classPublicId}
            onPress={() =>
              run('joinMeeting', () =>
                WiseSDK.joinMeeting({
                  classPublicId: details.classPublicId,
                  displayName,
                }),
              )
            }
          />

          <Text style={styles.section}>
            Sign in {signedIn ? '· Signed in ✓' : '(once per install)'}
          </Text>
          <Text style={styles.label}>SSO token</Text>
          <TextInput
            style={[styles.input, styles.token, signedIn && styles.disabled]}
            placeholderTextColor={PLACEHOLDER}
            editable={!signedIn}
            value={ssoToken}
            onChangeText={t => setSsoToken(t.replace(/\s+/g, ''))}
            placeholder={
              signedIn
                ? 'Already signed in'
                : 'JWT signed by your backend (eyJ...)'
            }
            multiline
            autoCapitalize="none"
            autoCorrect={false}
          />
          <View style={styles.row}>
            <Button
              title="Sign in"
              disabled={!ready || !ssoToken || signedIn}
              onPress={() =>
                run('loginUsingSSOToken', async () => {
                  await WiseSDK.loginUsingSSOToken(ssoToken);
                  setSsoToken('');
                  setSignedIn(await WiseSDK.isLoggedIn());
                })
              }
            />
            <Button
              title="Sign out"
              disabled={!signedIn}
              onPress={() =>
                run('logoutSSO', async () => {
                  WiseSDK.logoutSSO();
                  setSignedIn(await WiseSDK.isLoggedIn());
                })
              }
            />
          </View>

          <Text style={styles.section}>Signed-in user</Text>
          <Field
            label="Class ID"
            placeholder="24-character class ID"
            value={details.classId}
            onChange={set('classId')}
          />
          <View style={styles.row}>
            <Button
              title="Join class"
              disabled={!ready || !details.classId}
              onPress={() =>
                run('joinMeeting', () =>
                  WiseSDK.joinMeeting({ classId: details.classId }),
                )
              }
            />
            <Button
              title="Start class (teacher)"
              disabled={!ready || !details.classId}
              onPress={() =>
                run('startMeeting', () =>
                  WiseSDK.startMeeting({ classId: details.classId }),
                )
              }
            />
          </View>

          <Text style={styles.section}>Events</Text>
          <View style={styles.log}>
            {log.map((line, i) => (
              <Text key={i} style={styles.logLine}>
                {line}
              </Text>
            ))}
          </View>
        </ScrollView>
      </SafeAreaView>
    </SafeAreaProvider>
  );
}

const PLACEHOLDER = '#8a8a8a';

function Field(props: {
  label: string;
  placeholder: string;
  value: string;
  onChange: (v: string) => void;
}) {
  return (
    <View style={styles.field}>
      <Text style={styles.label}>{props.label}</Text>
      <TextInput
        style={styles.input}
        placeholder={props.placeholder}
        placeholderTextColor={PLACEHOLDER}
        value={props.value}
        onChangeText={props.onChange}
        autoCapitalize="none"
        autoCorrect={false}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#fff' },
  content: { padding: 16, gap: 8 },
  title: { fontSize: 20, fontWeight: '600' },
  section: { fontSize: 15, fontWeight: '600', marginTop: 16 },
  field: { gap: 4 },
  label: { fontSize: 12, color: '#555' },
  input: {
    borderWidth: 1,
    borderColor: '#ccc',
    borderRadius: 6,
    padding: 8,
    color: '#000',
  },
  token: {
    minHeight: 80,
    fontFamily: Platform.OS === 'ios' ? 'Menlo' : 'monospace',
    fontSize: 12,
  },
  disabled: { backgroundColor: '#f2f2f2', color: '#999' },
  row: { flexDirection: 'row', gap: 12, flexWrap: 'wrap' },
  log: {
    backgroundColor: '#f4f4f4',
    borderRadius: 6,
    padding: 8,
    minHeight: 100,
  },
  logLine: {
    fontFamily: Platform.OS === 'ios' ? 'Menlo' : 'monospace',
    fontSize: 11,
    marginBottom: 4,
  },
});
