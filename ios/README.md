# Wise SDK – iOS sample

## Run

Needs Xcode 26+ and CocoaPods.

1. Create `Config.local.xcconfig` with your IDs (see `Config.xcconfig`):
   ```
   WISE_BUNDLE_ID = com.yourcompany.wisesample
   WISE_TEAM_ID = ABCDE12345
   WISE_APP_GROUP = group.com.yourcompany.wisesample
   ```
2. Run `pod install`, open `WiseSample.xcworkspace` and run on a device.

In the app, enter your namespace and class IDs, tap **Initialize**, then join.

Integration guide: [iOS](https://unity.wiki/p/doc_3xlu2dxabk4iwpzp)
