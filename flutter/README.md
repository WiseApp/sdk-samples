# Wise SDK – Flutter sample

## Run

Needs Flutter 3.24+ (the sample is on 3.50). iOS also needs Xcode 26+ and CocoaPods.

- **Android:** `flutter run --release`
- **iOS:** create `ios/Wise.local.xcconfig` with your IDs (see `ios/Wise.xcconfig`), then run `flutter run --release` on a device:
  ```
  WISE_BUNDLE_ID = com.yourcompany.wisesample
  WISE_TEAM_ID = ABCDE12345
  WISE_APP_GROUP = group.com.yourcompany.wisesample
  ```

In the app, enter your namespace and class IDs, tap **Initialize**, then join.

Integration guide: [Flutter](https://unity.wiki/p/doc_q56lwhjtmz6f5p7r)
