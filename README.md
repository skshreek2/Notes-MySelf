Run this command to set the bridging header path in the .xcodeproj:

cd ios
xcodebuild -project RNDeviceHelper.xcodeproj \
  -target RNDeviceHelper \
  -configuration Debug \
  GCC_PREPROCESSOR_DEFINITIONS='$(inherited)' \
  SWIFT_OBJC_BRIDGING_HEADER='$(PROJECT_DIR)/RNDeviceHelper-Bridging-Header.h'


Then again for Release:
xcodebuild -project RNDeviceHelper.xcodeproj \
  -target RNDeviceHelper \
  -configuration Release \
  GCC_PREPROCESSOR_DEFINITIONS='$(inherited)' \
  SWIFT_OBJC_BRIDGING_HEADER='$(PROJECT_DIR)/RNDeviceHelper-Bridging-Header.h'


Check the setting value with:
grep -r "SWIFT_OBJC_BRIDGING_HEADER" ios/RNDeviceHelper.xcodeproj

You should see something like:
SWIFT_OBJC_BRIDGING_HEADER = "$(PROJECT_DIR)/RNDeviceHelper-Bridging-Header.h";
