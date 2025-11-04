
     
  15 |       let amps = AMPSPaymentProvider()
> 16 |       amps.initialize {status, error in
     |                       ^ escaping closure captures non-escaping parameter 'resolve'
  17 |           print(status)
  18 |       
  19 |           if status == true {



RNDeviceHelper-Bridging-Header.h:1:9: error: 'React/RCTBridgeModule.h' file not found
#import <React/RCTBridgeModule.h>
