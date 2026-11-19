import { ConfigContext, ExpoConfig } from 'expo/config';
import fs from 'fs';

// Your values live in wise.config.json (git-ignored). Copy wise.config.example.json to start.
const wise = JSON.parse(
  fs.readFileSync(fs.existsSync('./wise.config.json') ? './wise.config.json' : './wise.config.example.json', 'utf8')
);

// The broadcast extension reads the App Group from its Info.plist (WiseAppGroup).
// Written here so wise.config.json is the only place to change it (the file is git-ignored).
fs.writeFileSync(
  './targets/ScreenShare/Info.plist',
  `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>WiseAppGroup</key>
  <string>${wise.ios.appGroup}</string>
  <key>NSExtension</key>
  <dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.broadcast-services-upload</string>
    <key>NSExtensionPrincipalClass</key>
    <string>$(PRODUCT_MODULE_NAME).SampleHandler</string>
    <key>RPBroadcastProcessMode</key>
    <string>RPBroadcastProcessModeSampleBuffer</string>
  </dict>
</dict>
</plist>
`
);

export default ({ config }: ConfigContext): ExpoConfig => ({
  ...(config as ExpoConfig),
  name: 'Wise Sample',
  slug: 'wise-sample',
  ios: {
    ...config.ios,
    bundleIdentifier: wise.ios.bundleIdentifier,
    appleTeamId: wise.ios.appleTeamId,
    entitlements: { 'com.apple.security.application-groups': [wise.ios.appGroup] },
  },
  android: { ...config.android, package: wise.android.package },
  plugins: ['@wiseapp/react-native-sdk', '@bacons/apple-targets'],
  extra: { ...config.extra, wise },
});
