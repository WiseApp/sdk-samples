// iOS Broadcast Upload Extension for Wise screen sharing (built by @bacons/apple-targets).
const fs = require('fs');
const path = require('path');

const file = ['wise.config.json', 'wise.config.example.json']
  .map((f) => path.join(__dirname, '../..', f))
  .find((f) => fs.existsSync(f));
const wise = JSON.parse(fs.readFileSync(file, 'utf8'));

/** @type {import('@bacons/apple-targets/app.plugin').ConfigFunction} */
module.exports = (config) => ({
  type: 'broadcast-upload',
  name: 'ScreenShare',
  bundleIdentifier: wise.ios.screenShareBundleIdentifier,
  deploymentTarget: '15.1',
  entitlements: {
    'com.apple.security.application-groups': config.ios.entitlements['com.apple.security.application-groups'],
  },
});
