# Wise SDK – Expo sample

## Run

Expo SDK 57 needs Xcode 27 for iOS builds.

```bash
cp wise.config.example.json wise.config.json   # your bundle IDs, Apple team and App Group
npm install
npx expo prebuild --clean
npx expo run:android --variant release
npx expo run:ios --configuration Release --device
```

In the app, enter your namespace and class IDs, tap **Initialize**, then join.

Integration guide: [React Native](https://unity.wiki/p/doc_kzvb7joddskarkw4)
