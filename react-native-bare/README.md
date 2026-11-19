# Wise SDK – React Native sample (without Expo)

## Run

Needs Node 20+, Xcode 26+ and CocoaPods.

```bash
npm install
cd ios && pod install && cd ..
npx react-native run-android --mode release
npx react-native run-ios --mode Release
```

To run on an iPhone, open `ios/WiseSample.xcworkspace` and pick your team under Signing & Capabilities.

In the app, enter your namespace and class IDs, tap **Initialize**, then join.

Integration guide: [React Native](https://unity.wiki/p/doc_kzvb7joddskarkw4)
