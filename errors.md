
error: Multiple commands produce '/Users/s82988/Library/Developer/Xcode/DerivedData/HDFCBankMobileBanking-fvmfzldupohvbdgltijpuobemnuv/Build/Products/Debug-iphoneos/react-native-pf-issuer/react_native_pf_issuer.framework/Headers/acquirerGateway.h'
    note: Target 'react-native-pf-issuer' (project 'Pods') has copy command from '/Users/s82988/Documents/Projects/Mobile-Banking-UI/node_modules/react-native-pf-issuer/ios/PfAmpsNativeKit.xcframework/ios-arm64/PfAmpsNativeKit.framework/Headers/acquirerGateway.h' to '/Users/s82988/Library/Developer/Xcode/DerivedData/HDFCBankMobileBanking-fvmfzldupohvbdgltijpuobemnuv/Build/Products/Debug-iphoneos/react-native-pf-issuer/react_native_pf_issuer.framework/Headers/acquirerGateway.h'
    note: Target 'react-native-pf-issuer' (project 'Pods') has copy command from '/Users/s82988/Documents/Projects/Mobile-Banking-UI/node_modules/react-native-pf-issuer/ios/PfAmpsNativeKit.xcframework/ios-arm64_x86_64-simulator/PfAmpsNativeKit.framework/Headers/acquirerGateway.h' to '/Users/s82988/Library/Developer/Xcode/DerivedData/HDFCBankMobileBanking-fvmfzldupohvbdgltijpuobemnuv/Build/Products/Debug-iphoneos/react-native-pf-issuer/react_native_pf_issuer.framework/Headers/acquirerGateway.h'



export const PaymentAquirerBridge = async (): Promise<any> => {
  try {
    const result = await RNPfNbblIssuerView.initializeAndLaunch();
    return result;
  } catch (error) {
    console.error('Error launching acquirer:', error);
    throw error;
  }
};







import {
  Platform,
  NativeModules,
} from 'react-native';

const LINKING_ERROR =
  `The package 'react-native-pf-issuer' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

export const RNPfNbblIssuerView = NativeModules.HdfcIssuerBridge
  ? NativeModules.HdfcIssuerBridge
  : new Proxy(
    {},
    {
      get() {
        throw new Error(LINKING_ERROR);
      },
    }
  );

export const PaymentIssuerBridge = (data: string) => {
  RNPfNbblIssuerView.payment(data).then((res: any, error: any) => {
    console.log(res, error);
  });
  
};

export const PaymentAquirerBridge = () => { 
  RNPfNbblIssuerView.initializeAndLaunch(): Promise<string> {
    return NativeModule.initializeAndLaunch();
  }
};







❌  error: Using bridging headers with framework targets is unsupported (in target 'react-native-testbridge-new' from project 'Pods')


❌error: Build input file cannot be found: '/Users/s82988/Documents/POC/TestAppRNLibrary-main/node_modules/react-native-testbridge-new/ios/RNDeviceHelper-Bridging-Header.h'. Did you forget to declare this file as an output of a script phase or custom build rule which produces it? (in target 'react-native-testbridge-new' from project 'Pods')





[UIKitCore] Modifying properties of a view's layer off the main thread is not allowed: view <PfAmpsNativeKit.AMPSWebview: 0x1057050e0> with no
associated or ancestor view controller; backtrace:
     
  15 |       let amps = AMPSPaymentProvider()
> 16 |       amps.initialize {status, error in
     |                       ^ escaping closure captures non-escaping parameter 'resolve'
  17 |           print(status)
  18 |       
  19 |           if status == true {



RNDeviceHelper-Bridging-Header.h:1:9: error: 'React/RCTBridgeModule.h' file not found
#import <React/RCTBridgeModule.h>
