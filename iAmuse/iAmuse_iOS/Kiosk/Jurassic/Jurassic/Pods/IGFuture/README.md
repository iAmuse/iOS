## IGFuture

Futures pattern in Objective-C.

### Why?

Inspired by [futuristic](https://github.com/seanlilmateus/futuristic), I want to see if it is possible to be done in Objective-C. Turns out it has been done previously (a.k.a. [MAFuture](https://github.com/mikeash/MAFuture)),
but why not reinvent it?

This is highly experimental, so use it at your own risk!

### Example

```objective-c
NSDate* now = [NSDate date];
NSDate* later = (NSDate*) [[IGFuture alloc] initWithBlock:^id{
    // perform some long running task
    [NSThread sleepForTimeInterval:1];

    // return the value
    return [NSDate date];
}];

expect([later timeIntervalSinceDate:now]).to.beCloseToWithin(1, 0.01);
```

1. The future block run immediately in background. When it is needed (at ```[later timeIntervalSinceDate:now]```) and the result is available, it returns immediately. If it is still running, it block and wait for completion. 

2. If you want the future only calculate the results when it is needed, use ```-initWithLazyBlock:```.

3. Note "later" which is a IGFuture object can be used as a NSDate (the returned value of the block).

### Real(-ish) example

```objective-c
IGFuture* future = [[IGFuture alloc] initWithBlock:^id{
    // perform some long running task
    [NSThread sleepForTimeInterval:3.0];
    return @[@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10"];
}];

future.completionBlock = ^(NSArray* data) {
    self.data = data;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
};
```

### Usage

In your ```Podfile```

```
pod 'IGFuture', '~> 0.2.1'
```


### Copyright

Copyright (c) 2013 Francis Chong. This software is licensed under the MIT License. See LICENSE for details.