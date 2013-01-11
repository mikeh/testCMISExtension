/*
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
 */

#import <Foundation/Foundation.h>
#import "CMISSessionParameters.h"
#import "CMISBindingSession.h"
#import "CMISNetworkProvider.h"
#import "CMISHttpInvokerDelegate.h"
#import "CMISRequest.h"

@interface CMISAtomPubBaseService : NSObject

@property (nonatomic, strong, readonly) CMISBindingSession *bindingSession;
@property (nonatomic, strong, readonly) NSURL *atomPubUrl;
@property (nonatomic, strong, readonly) CMISNetworkProvider *provider;
@property (nonatomic, strong, readonly) id<CMISHttpInvokerDelegate> networkInvoker;
@property (nonatomic, strong) CMISRequest *currentHttpRequest;

- (id)initWithBindingSession:(CMISBindingSession *)session;
- (void)clearCacheFromService;
@end
