

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
