//  Copyright (c) 2021 650 Industries, Inc. All rights reserved.

#import <XCTest/XCTest.h>

#import <EXUpdates/EXUpdatesErrorRecovery.h>

#import <OCHamcrest/OCHamcrest.h>
#import <OCMockito/OCMockito.h>

@interface EXUpdatesErrorRecoveryTests : XCTestCase

@property (nonatomic, strong) EXUpdatesErrorRecovery *errorRecovery;
@property (nonatomic, strong) dispatch_queue_t testQueue;
@property (nonatomic, strong) EXUpdatesDatabase *mockDatabase;

@end

@implementation EXUpdatesErrorRecoveryTests

- (void)setUp
{
  _testQueue = dispatch_queue_create("expo.errorRecoveryTestQueue", DISPATCH_QUEUE_SERIAL);
  _errorRecovery = [[EXUpdatesErrorRecovery alloc] initWithErrorRecoveryQueue:_testQueue remoteLoadTimeout:500];
  _mockDatabase = mock([EXUpdatesDatabase class]);
  [given(_mockDatabase.databaseQueue) willReturn:_testQueue];
}

- (void)tearDown
{
  // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testHandleError_NewWorkingUpdateAlreadyLoaded
{
  id<EXUpdatesErrorRecoveryDelegate> mockDelegate = mockProtocol(@protocol(EXUpdatesErrorRecoveryDelegate));
  _errorRecovery.delegate = mockDelegate;

  [given(mockDelegate.remoteLoadStatus) willReturnInteger:EXUpdatesRemoteLoadStatusNewUpdateLoaded];

  NSError *mockError = mock([NSError class]);
  [_errorRecovery handleError:mockError];
  dispatch_sync(_testQueue, ^{}); // flush queue

  [verify(mockDelegate) markFailedLaunchForLaunchedUpdate];
  [self verifySuccessfulRelaunchWithCompletion_WithMockDelegate:mockDelegate];
  [verifyCount(mockDelegate, never()) relaunchWithCompletion:(id)anything()];
  [verifyCount(mockDelegate, never()) loadRemoteUpdate];
  [verifyCount(mockDelegate, never()) throwException:anything()];
}

- (void)testHandleError_NewWorkingUpdateLoading
{
  id<EXUpdatesErrorRecoveryDelegate> mockDelegate = mockProtocol(@protocol(EXUpdatesErrorRecoveryDelegate));
  _errorRecovery.delegate = mockDelegate;

  [given(mockDelegate.remoteLoadStatus) willReturnInteger:EXUpdatesRemoteLoadStatusLoading];

  NSError *mockError = mock([NSError class]);
  [_errorRecovery handleError:mockError];

  [given(mockDelegate.remoteLoadStatus) willReturnInteger:EXUpdatesRemoteLoadStatusNewUpdateLoaded];
  [_errorRecovery notifyNewRemoteLoadStatus:EXUpdatesRemoteLoadStatusNewUpdateLoaded];
  dispatch_sync(_testQueue, ^{}); // flush queue

  [verify(mockDelegate) markFailedLaunchForLaunchedUpdate];
  [self verifySuccessfulRelaunchWithCompletion_WithMockDelegate:mockDelegate];
  [verifyCount(mockDelegate, never()) relaunchWithCompletion:(id)anything()];
  [verifyCount(mockDelegate, never()) loadRemoteUpdate];
  [verifyCount(mockDelegate, never()) throwException:anything()];
}

- (void)testHandleError_NewBrokenUpdateLoaded_WorkingUpdateCached
{
  id<EXUpdatesErrorRecoveryDelegate> mockDelegate = mockProtocol(@protocol(EXUpdatesErrorRecoveryDelegate));
  _errorRecovery.delegate = mockDelegate;

  [given(mockDelegate.remoteLoadStatus) willReturnInteger:EXUpdatesRemoteLoadStatusNewUpdateLoaded];

  NSError *mockError = mock([NSError class]);
  [_errorRecovery handleError:mockError];
  dispatch_sync(_testQueue, ^{}); // flush queue

  [verify(mockDelegate) markFailedLaunchForLaunchedUpdate];
  [self verifySuccessfulRelaunchWithCompletion_WithMockDelegate:mockDelegate];

  NSError *mockError2 = mock([NSError class]);
  [_errorRecovery handleError:mockError2];
  dispatch_sync(_testQueue, ^{}); // flush queue

  [verify(mockDelegate) markFailedLaunchForLaunchedUpdate];
  [self verifySuccessfulRelaunchWithCompletion_WithMockDelegate:mockDelegate];
  [verifyCount(mockDelegate, never()) loadRemoteUpdate];
  [verifyCount(mockDelegate, never()) throwException:anything()];
}

- (void)testHandleError_NewBrokenUpdateLoaded_UpdateAlreadyLaunchedSuccessfully
{
  // if an update has already been launched successfully, we don't want to fall back to an older update

  id<EXUpdatesErrorRecoveryDelegate> mockDelegate = mockProtocol(@protocol(EXUpdatesErrorRecoveryDelegate));
  _errorRecovery.delegate = mockDelegate;

  EXUpdatesUpdate *mockUpdate = mock([EXUpdatesUpdate class]);
  [given(mockUpdate.successfulLaunchCount) willReturnInteger:1];

  [given(mockDelegate.launchedUpdate) willReturn:mockUpdate];
  [given(mockDelegate.remoteLoadStatus) willReturnInteger:EXUpdatesRemoteLoadStatusNewUpdateLoaded];

  NSError *mockError = mock([NSError class]);
  [_errorRecovery handleError:mockError];
  dispatch_sync(_testQueue, ^{}); // flush queue

  [verifyCount(mockDelegate, never()) markFailedLaunchForLaunchedUpdate];
  [self verifySuccessfulRelaunchWithCompletion_WithMockDelegate:mockDelegate];

  [given(mockUpdate.successfulLaunchCount) willReturnInteger:0];
  NSError *mockError2 = mock([NSError class]);
  [_errorRecovery handleError:mockError2];
  dispatch_sync(_testQueue, ^{}); // flush queue

  [verify(mockDelegate) markFailedLaunchForLaunchedUpdate];
  [verify(mockDelegate) throwException:anything()];
  [verifyCount(mockDelegate, never()) relaunchWithCompletion:anything()];
  [verifyCount(mockDelegate, never()) loadRemoteUpdate];
}

- (void)testHandleError_RemoteLoadTimesOut
{
  id<EXUpdatesErrorRecoveryDelegate> mockDelegate = mockProtocol(@protocol(EXUpdatesErrorRecoveryDelegate));
  _errorRecovery.delegate = mockDelegate;

  [given(mockDelegate.remoteLoadStatus) willReturnInteger:EXUpdatesRemoteLoadStatusLoading];

  NSError *mockError = mock([NSError class]);
  [_errorRecovery handleError:mockError];

  // wait for more than 500ms
  [NSThread sleepForTimeInterval:0.6f];
  dispatch_sync(_testQueue, ^{}); // flush queue

  [verify(mockDelegate) markFailedLaunchForLaunchedUpdate];
  [self verifySuccessfulRelaunchWithCompletion_WithMockDelegate:mockDelegate];
  [verifyCount(mockDelegate, never()) loadRemoteUpdate];
  [verifyCount(mockDelegate, never()) throwException:anything()];
}

- (void)testHandleError_RemoteLoadTimesOut_UpdateAlreadyLaunchedSuccessfully
{
  // if an update has already been launched successfully, we don't want to fall back to an older update

  id<EXUpdatesErrorRecoveryDelegate> mockDelegate = mockProtocol(@protocol(EXUpdatesErrorRecoveryDelegate));
  _errorRecovery.delegate = mockDelegate;

  EXUpdatesUpdate *mockUpdate = mock([EXUpdatesUpdate class]);
  [given(mockUpdate.successfulLaunchCount) willReturnInteger:1];

  [given(mockDelegate.launchedUpdate) willReturn:mockUpdate];
  [given(mockDelegate.remoteLoadStatus) willReturnInteger:EXUpdatesRemoteLoadStatusLoading];

  NSError *mockError = mock([NSError class]);
  [_errorRecovery handleError:mockError];

  // wait for more than 500ms
  [NSThread sleepForTimeInterval:0.6f];
  dispatch_sync(_testQueue, ^{}); // flush queue

  [verify(mockDelegate) throwException:anything()];
  [verifyCount(mockDelegate, never()) markFailedLaunchForLaunchedUpdate];
  [verifyCount(mockDelegate, never()) relaunchWithCompletion:anything()];
  [verifyCount(mockDelegate, never()) loadRemoteUpdate];
}

- (void)testHandleError_RemoteLoadTimesOut_RCTContentDidAppear
{
  id<EXUpdatesErrorRecoveryDelegate> mockDelegate = mockProtocol(@protocol(EXUpdatesErrorRecoveryDelegate));
  _errorRecovery.delegate = mockDelegate;

  [given(mockDelegate.remoteLoadStatus) willReturnInteger:EXUpdatesRemoteLoadStatusLoading];

  [_errorRecovery startMonitoring];
  [[NSNotificationCenter defaultCenter] postNotificationName:@"RCTContentDidAppearNotification" object:nil];
  [verify(mockDelegate) markSuccessfulLaunchForLaunchedUpdate];

  // if RCTContentDidAppear has already fired, we don't want to roll back to an older update
  NSError *mockError = mock([NSError class]);
  [_errorRecovery handleError:mockError];

  // wait for more than 500ms
  [NSThread sleepForTimeInterval:0.6f];
  dispatch_sync(_testQueue, ^{}); // flush queue

  [verify(mockDelegate) throwException:anything()];
  [verifyCount(mockDelegate, never()) markFailedLaunchForLaunchedUpdate];
  [verifyCount(mockDelegate, never()) relaunchWithCompletion:anything()];
  [verifyCount(mockDelegate, never()) loadRemoteUpdate];
}

- (void)testHandleError_NoRemoteUpdate
{
  id<EXUpdatesErrorRecoveryDelegate> mockDelegate = mockProtocol(@protocol(EXUpdatesErrorRecoveryDelegate));
  _errorRecovery.delegate = mockDelegate;

  [given(mockDelegate.remoteLoadStatus) willReturnInteger:EXUpdatesRemoteLoadStatusIdle];

  NSError *mockError = mock([NSError class]);
  [_errorRecovery handleError:mockError];
  dispatch_sync(_testQueue, ^{}); // flush queue

  [verify(mockDelegate) markFailedLaunchForLaunchedUpdate];
  // should try to load a remote update since we don't have one already
  [verify(mockDelegate) loadRemoteUpdate];

  // indicate there isn't a new update from the server
  [_errorRecovery notifyNewRemoteLoadStatus:EXUpdatesRemoteLoadStatusIdle];
  dispatch_sync(_testQueue, ^{}); // flush queue
  [verify(mockDelegate) throwException:anything()];
}

- (void)testHandleTwoErrors
{
  id<EXUpdatesErrorRecoveryDelegate> mockDelegate = mockProtocol(@protocol(EXUpdatesErrorRecoveryDelegate));
  _errorRecovery.delegate = mockDelegate;

  [given(mockDelegate.remoteLoadStatus) willReturnInteger:EXUpdatesRemoteLoadStatusIdle];

  NSError *mockError = mock([NSError class]);
  [_errorRecovery handleError:mockError];
  [_errorRecovery handleError:mockError];
  dispatch_sync(_testQueue, ^{}); // flush queue

  // the actual error recovery should only happen once despite there being two errors
  [verifyCount(mockDelegate, times(1)) loadRemoteUpdate];
}

- (void)testHandleException
{
  id<EXUpdatesErrorRecoveryDelegate> mockDelegate = mockProtocol(@protocol(EXUpdatesErrorRecoveryDelegate));
  _errorRecovery.delegate = mockDelegate;

  [given(mockDelegate.remoteLoadStatus) willReturnInteger:EXUpdatesRemoteLoadStatusNewUpdateLoaded];

  NSException *mockException = mock([NSException class]);
  [_errorRecovery handleException:mockException];
  dispatch_sync(_testQueue, ^{}); // flush queue

  [verify(mockDelegate) markFailedLaunchForLaunchedUpdate];
  [self verifySuccessfulRelaunchWithCompletion_WithMockDelegate:mockDelegate];
  [verifyCount(mockDelegate, never()) relaunchWithCompletion:(id)anything()];
  [verifyCount(mockDelegate, never()) loadRemoteUpdate];
  [verifyCount(mockDelegate, never()) throwException:anything()];
}

- (void)verifySuccessfulRelaunchWithCompletion_WithMockDelegate:(id<EXUpdatesErrorRecoveryDelegate>)mockDelegate
{
  HCArgumentCaptor *argument = [[HCArgumentCaptor alloc] init];
  [verify(mockDelegate) relaunchWithCompletion:(id)argument];
  EXUpdatesAppLauncherCompletionBlock completion = argument.value;
  completion(nil, YES);
  dispatch_sync(_testQueue, ^{}); // flush queue
}

- (void)verifyFailedRelaunchWithCompletion_WithMockDelegate:(id<EXUpdatesErrorRecoveryDelegate>)mockDelegate
{
  HCArgumentCaptor *argument = [[HCArgumentCaptor alloc] init];
  [verify(mockDelegate) relaunchWithCompletion:(id)argument];
  EXUpdatesAppLauncherCompletionBlock completion = argument.value;
  completion(mock([NSError class]), NO);
  dispatch_sync(_testQueue, ^{}); // flush queue
}

@end
