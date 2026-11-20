# Wise SDK – React Native sample (without Expo)

## Run

Needs Node 20+, Xcode 26+ and CocoaPods.

```bash
npm install
cd ios && pod install && cd ..
npx react-native run-android --mode release
npx react-native run-ios --mode Release
```

To run on an iPhone or iPad, create `ios/Config.local.xcconfig` (git-ignored) with your own IDs:

```
WISE_BUNDLE_ID = com.yourcompany.wisesample
WISE_TEAM_ID = ABCDE12345
WISE_APP_GROUP = group.com.yourcompany.wisesample
```

In the app, enter your namespace and class IDs, tap **Initialize**, then join.

**Screen share (iOS):** the `ScreenShare` target is the Broadcast Upload Extension. Its bundle ID is
`WISE_BUNDLE_ID` + `.ScreenShare`, and the app and extension share `WISE_APP_GROUP`. After **Initialize**
the app calls `WiseSDK.enableScreenShare` with them. In a class, tap **Share** and pick
**Wise Sample Screen Share**. Screen sharing needs a real device.

Integration guide: [React Native](https://unity.wiki/p/doc_kzvb7joddskarkw4)
