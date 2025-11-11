


"FRAMEWORK_SEARCH_PATHS" => "\"$(PODS_ROOT)/../../ios\" \"$(PODS_TARGET_SRCROOT)/ios\""




***podspec**

require 'json'

package = JSON.parse(File.read(File.join(__dir__, '../package.json')))

Pod::Spec.new do |s|
  s.name         = "RNDeviceHelper"
  s.version      = package['version']
  s.summary      = "React Native Device Helper module"
  s.description  = package['description']
  s.homepage     = package['homepage']
  s.license      = package['license']
  s.author       = package['author']
  s.platforms    = { :ios => "12.0" }

  # 👇 this path is relative to your podspec file
  s.source_files = "RNDeviceHelper/**/*.{h,m,mm,swift}"
  s.public_header_files = "RNDeviceHelper/**/*.h"

  # 👇 include bridging header manually if needed
  s.pod_target_xcconfig = {
    'SWIFT_OBJC_BRIDGING_HEADER' => '$(PODS_TARGET_SRCROOT)/RNDeviceHelper-Bridging-Header.h',
    'SWIFT_VERSION' => '5.0'
  }

  s.dependency 'React-Core'
  s.dependency 'React-RCTBridge'
  s.dependency 'ReactCommon/turbomodule/core'

  s.source = { :path => '.' }
end


------------------------------------------------------------




In Xcode:
Build Settings → Swift Compiler - General → Objective-C Bridging Header
$(PROJECT_DIR)/RNDeviceHelper-Bridging-Header.h
-----------------------------------------------------------------------


Add it in Applications (in our case it is Testing App)
pod 'react-native-device-helper', :path => '../node_modules/react-native-device-helper/ios'

-------------------------------------------------------------------------------------------

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
