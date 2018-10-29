// Part of MeasurementKit <https://measurement-kit.github.io/>.
// MeasurementKit is free software. See AUTHORS and LICENSE for more
// information on the copying conditions.

#import "NetworkMeasurement.h"

#import "MkTask.h"

@implementation NetworkMeasurement

+(void) run:(BOOL)verbose {
  // Note: the emulator does not cope well with receiving
  // a signal of type SIGPIPE when the debugger is attached
  // See http://stackoverflow.com/questions/1294436

  NSBundle *bundle = [NSBundle mainBundle];
  NSDictionary *settings = @{
    @"log_level": (verbose) ? @"DEBUG" : @"INFO",
    @"name": @"Ndt",
    @"options": @{
      @"geoip_country_path": [bundle pathForResource:@"GeoIP" ofType:@"dat"],
      @"geoip_asn_path": [bundle pathForResource:@"GeoIPASNum" ofType:@"dat"],
      @"no_file_report": @YES,
    }
  };

  dispatch_async(
    dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      MkTask *task = [MkTask startNettest:settings];
      while (![task isDone]) {
        // Extract an event from the task queue and unmarshal it.
        NSDictionary *evinfo = [task waitForNextEvent];
        if (evinfo == nil) abort();
        // Notify the main thread about the latest event.
        dispatch_async(dispatch_get_main_queue(), ^{
          [[NSNotificationCenter defaultCenter]
            postNotificationName:@"event" object:nil userInfo:evinfo];
        });
      }
      // Notify the main thread that the task is now complete
      dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter]
          postNotificationName:@"test_complete" object:nil];
      });
  });
}

@end
