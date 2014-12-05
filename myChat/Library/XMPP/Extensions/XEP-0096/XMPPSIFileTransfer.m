//
//  MultiCast.m
//  TrustTextXMPP
//
//  Created by 戴维营教育 on 10/11/2014.
//  Copyright (c) 2014 戴维营教育. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "XMPPSIFileTransfer.h"
#import "XMPPLogging.h"
#import "XMPPMessage.h"
#import "NSXMLElement+XMPP.h"
#import "TURNSocket.h"

#if DEBUG
    static const int xmppLogLevel = XMPP_LOG_LEVEL_WARN; // | XMPP_LOG_FLAG_TRACE;
#else
    static const int xmppLogLevel = XMPP_LOG_LEVEL_WARN;
#endif

@interface XMPPSIFileTransfer()
@property (nonatomic, readwrite) NSUInteger recvFileSize;
@property (nonatomic, readwrite) NSUInteger sendFileSize;
@property (nonatomic, strong) NSData *fileToSend;
@property (nonatomic, strong) NSString *fileRecipient;
@property (nonatomic, strong) NSString *recvFileName;
@end

@implementation XMPPSIFileTransfer
@synthesize sid;
@synthesize recvFileSize;
@synthesize fileToSend;
@synthesize recvFileName;

- (id)init {
    return [self initWithDispatchQueue:NULL];
}

- (id)initWithDispatchQueue:(dispatch_queue_t)queue {
	if ((self = [super initWithDispatchQueue:queue])) {
        state = kXMPPSIFileTransferStateNone;
        receivedData = [[NSMutableData alloc] init];
	}
	return self;
}

- (BOOL)activate:(XMPPStream *)aXmppStream {
	if ([super activate:aXmppStream]) {
		return YES;
	}
	return NO;
}

- (void)deactivate {
    XMPPLogTrace();
    
	[super deactivate];
}

- (BOOL)sendNegotiationResponse:(XMPPIQ*)inIq {
    NSString *iqId = [inIq attributeStringValueForName:@"id"];
    NSString *from = [inIq fromStr];
    NSString *to = [inIq toStr];

    NSXMLElement *si = [inIq elementForName:@"si"];
    NSXMLElement *file = [si elementForName:@"file"];
    NSXMLElement *feature = [[inIq elementForName:@"si"] elementForName:@"feature"];
    
    // sid is an important value, which will be used throughtout.
    // It will be referred back to by other IQs involving file tranfers.
    self.sid = [[si attributeForName:@"id"] stringValue];
    self.recvFileSize = (NSUInteger)[[[file attributeForName:@"size"] stringValue] integerValue];
    self.recvFileName = [[file attributeForName:@"name"] stringValue];
    NSString *fileMimeType = [[[inIq childElement] attributeForName:@"mime-type"] stringValue];
    
    if ([@"image/jpg" caseInsensitiveCompare:fileMimeType] == NSOrderedSame
        || [@"image/jpeg" caseInsensitiveCompare:fileMimeType] == NSOrderedSame)
    {
        mimeType = kXMPPSIFileTransferMimeTypeJPG;
    }
    else if ([@"image/gif" isEqualToString:fileMimeType] == YES)
    {
        mimeType = kXMPPSIFileTransferMimeTypeGIF;
    }
    else if ([@"image/png" isEqualToString:fileMimeType] == YES)
    {
        mimeType = kXMPPSIFileTransferMimeTypePNG;
    }
    else if ([@"audio/mp3" isEqualToString:fileMimeType] == YES)
    {
        mimeType = kXMPPSIFileTransferMimeTypeMP3;
    }else if ([@"audio/opus" isEqualToString:fileMimeType] == YES)
    {
        mimeType = kXMPPSIFileTransferMimeTypeOPUS;
    }else
    {
        NSString *fileExt = [[[file attributeForName:@"name"] stringValue] pathExtension];
        if ([fileExt caseInsensitiveCompare:@"jpg"] == NSOrderedSame ||
            [fileExt caseInsensitiveCompare:@"jpeg"]== NSOrderedSame) {
             mimeType = kXMPPSIFileTransferMimeTypeJPG;
        }else if ([fileExt caseInsensitiveCompare:@"gif"] == NSOrderedSame ){
            mimeType = kXMPPSIFileTransferMimeTypeGIF;
        }else if ([fileExt caseInsensitiveCompare:@"png"] == NSOrderedSame ){
            mimeType = kXMPPSIFileTransferMimeTypePNG;
        }else if ([fileExt caseInsensitiveCompare:@"mp3"] == NSOrderedSame ){
            mimeType = kXMPPSIFileTransferMimeTypeMP3;
        }else if ([fileExt caseInsensitiveCompare:@"opus"] == NSOrderedSame ){
            mimeType = kXMPPSIFileTransferMimeTypeOPUS;
        }
    }
    
    
    senderJID = [inIq from];
    
    NSXMLElement *field = [[feature elementForName:@"x"] elementForName:@"field"];
    NSArray *options = [field elementsForName:@"option"];
    for (NSXMLElement *option in options) {
        NSString *value = [[option elementForName:@"value"] stringValue];
        if ([@"http://jabber.org/protocol/bytestreams" isEqualToString:value]) {
            NSXMLElement *riq = [XMPPIQ iqWithType:@"result" elementID:iqId];
            [riq addAttributeWithName:@"from" stringValue:to];
            [riq addAttributeWithName:@"to" stringValue:from];
            
            NSXMLElement *rsi = [NSXMLElement elementWithName:@"si" xmlns:@"http://jabber.org/protocol/si"];
            [riq addChild:rsi];
            
            NSXMLElement *rfeature = [NSXMLElement elementWithName:@"feature" xmlns:@"http://jabber.org/protocol/feature-neg"];
            [rsi addChild:rfeature];
            
            NSXMLElement *rx = [NSXMLElement elementWithName:@"x" xmlns:@"jabber:x:data"];
            [rx addAttributeWithName:@"type" stringValue:@"submit"];
            [rfeature addChild:rx];
            
            NSXMLElement *rfield = [NSXMLElement elementWithName:@"field"];
            [rfield addAttributeWithName:@"var" stringValue:@"stream-method"];
            [rx addChild:rfield];
            
            NSXMLElement *rvalue = [NSXMLElement elementWithName:@"value" stringValue:@"http://jabber.org/protocol/bytestreams"];
            [rfield addChild:rvalue];
            
            [xmppStream sendElement:riq];
            
            return YES;
        }
    }
    return NO;
}

- (BOOL)sendStreamHostNegotiationError:(XMPPIQ*)inIq {
    NSString *to = [inIq fromStr];
    NSString *from = [inIq toStr];
    XMPPIQ *iq = [XMPPIQ iqWithType:@"error" elementID:[inIq elementID]];
    [iq addAttributeWithName:@"to" stringValue:to];
    [iq addAttributeWithName:@"from" stringValue:from];
    
    NSXMLElement *error = [NSXMLElement elementWithName:@"error"];
    [error addAttributeWithName:@"type" stringValue:@"modify"];
    [iq addChild:error];
    
    NSXMLElement *notAcc = [NSXMLElement elementWithName:@"not-acceptable" xmlns:@"urn:ietf:params:xml:ns:xmpp-stanzas"];
    [error addChild:notAcc];
    
    [xmppStream sendElement:iq];
    return YES;
}

- (BOOL)handleServiceDiscoveryRequest:(XMPPIQ*)inIq {
    NSString *from = [inIq toStr];
    NSString *to = [inIq fromStr];
    
    NSString *uuid = [xmppStream generateUUID];
    NSXMLElement *child = [NSXMLElement elementWithName:@"query" xmlns:@"http://jabber.org/protocol/disco#info"];
    XMPPIQ *iq = [XMPPIQ iqWithType:@"get" elementID:uuid child:child];
    [iq addAttributeWithName:@"to" stringValue:to];
    [iq addAttributeWithName:@"from" stringValue:from];
    [xmppStream sendElement:iq];
    
    [TURNSocket setProxyCandidates:[[NSArray alloc] initWithObjects:xmppStream.hostName, nil]];
    turnSocket = [[TURNSocket alloc] initWithStream:xmppStream toJID:[XMPPJID jidWithString:self.fileRecipient] sid:sid];
    [turnSocket startWithDelegate:self delegateQueue:dispatch_get_main_queue()];


    return YES;
}

- (BOOL)sendDiscoverProxies:(XMPPIQ*)inIq {
    NSString *from = [inIq toStr];
    NSString *to = [xmppStream hostName];
    
    NSString *uuid = [xmppStream generateUUID];
    NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:@"http://jabber.org/protocol/disco#items"];
    XMPPIQ *iq = [XMPPIQ iqWithType:@"get" elementID:uuid child:query];
    [iq addAttributeWithName:@"to" stringValue:to];
    [iq addAttributeWithName:@"from" stringValue:from];
    [xmppStream sendElement:iq];
    

    return YES;
}


- (void)initiateFileTransferTo:(XMPPJID*)toFullJID withData:(NSData*)data
                   andMimeType:(XMPPSIFileTransferMimeType)type andDataName:(NSString *)dataName
{
    if (nil == data || 0 == [data length]) {
        NSLog(@"the file data to be send can't be nil or empty");
        return;
    }
    NSString *toResource = [toFullJID resource];
    if (toResource == nil) {
        NSLog(@"you must specify a fullJID of the receiver. e.g. 147957232@qq.com/diveinedu");
        return;
    }
    // Set the current step number to simply which step we are in the multi-step
    // process of the file transfer handshake process. 
    step = 0;
    mimeType = type;
    NSString *extName, *mimeTypeStr;
    switch (mimeType) {
        case kXMPPSIFileTransferMimeTypeJPG:
            extName = @".jpg";
            mimeTypeStr = @"image/jpg";
            break;
        case kXMPPSIFileTransferMimeTypePNG:
            extName = @".png";
            mimeTypeStr = @"image/png";
            break;
        case kXMPPSIFileTransferMimeTypeGIF:
            extName = @".gif";
            mimeTypeStr = @"image/gif";
            break;
        case kXMPPSIFileTransferMimeTypeMP3:
            extName = @".mp3";
            mimeTypeStr = @"audio/mp3";
            break;
        case kXMPPSIFileTransferMimeTypeOPUS:
            extName = @".opus";
            mimeTypeStr = @"audio/opus";
            break;
        default:
            extName = @".dat";
            mimeTypeStr = @"binary/octet-stream";
            break;
    }
    if (nil == dataName || 0 == [dataName length]) {
        dataName = [[NSString alloc] initWithFormat:@"data%@%@", [[xmppStream generateUUID] substringToIndex:4], extName];
    }
    
    state = kXMPPSIFileTransferStateSending;
    fileToSend = data;
    self.fileRecipient = toFullJID.full;
    NSString *uuid = [xmppStream generateUUID];
    XMPPIQ *iq = [XMPPIQ iqWithType:@"set" elementID:uuid];
    [iq addAttributeWithName:@"to" stringValue:toFullJID.full];
    [iq addAttributeWithName:@"from" stringValue:[[xmppStream myJID] full]];
    
    sid = [xmppStream generateUUID];
    NSXMLElement *si = [NSXMLElement elementWithName:@"si" xmlns:@"http://jabber.org/protocol/si"];
    [si addAttributeWithName:@"id" stringValue:sid];
    [si addAttributeWithName:@"mime-type" stringValue:mimeTypeStr];
    [si addAttributeWithName:@"profile" stringValue:@"http://jabber.org/protocol/si/profile/file-transfer"];
    [iq addChild:si];
    

    
    NSString *fileName = dataName;
    NSXMLElement *file = [NSXMLElement elementWithName:@"file" xmlns:@"http://jabber.org/protocol/si/profile/file-transfer"];
    [file addAttributeWithName:@"name" stringValue:fileName];
    [file addAttributeWithName:@"size" stringValue:[[NSString alloc] initWithFormat:@"%lu", (unsigned long)[data length]]];
    [si addChild:file];
    
//        NSXMLElement *desc = [NSXMLElement elementWithName:@"desc" stringValue:@"sending file"];
//        [file addChild:desc];
    
    NSXMLElement *feature = [NSXMLElement elementWithName:@"feature" xmlns:@"http://jabber.org/protocol/feature-neg"];
    [si addChild:feature];
    
    NSXMLElement *x = [NSXMLElement elementWithName:@"x" xmlns:@"jabber:x:data"];
    [x addAttributeWithName:@"type" stringValue:@"form"];
    [feature addChild:x];
    
    NSXMLElement *field = [NSXMLElement elementWithName:@"field"];
    [field addAttributeWithName:@"var" stringValue:@"stream-method"];
    [field addAttributeWithName:@"type" stringValue:@"list-single"];
    [x addChild:field];
    
    NSXMLElement *option = [NSXMLElement elementWithName:@"option"];
    [field addChild:option];
    
    NSXMLElement *value = [NSXMLElement elementWithName:@"value" stringValue:@"http://jabber.org/protocol/bytestreams"];
    [option addChild:value];
    
    NSXMLElement *option2 = [NSXMLElement elementWithName:@"option"];
    [field addChild:option2];
    
    NSXMLElement *value2 = [NSXMLElement elementWithName:@"value" stringValue:@"http://jabber.org/protocol/ibb"];
    [option2 addChild:value2];
    [xmppStream sendElement:iq];
}


#pragma mark XMPPStream Delegate
/**
 * When we receive an IQ with namespaces http://jabber.org/protocol/si and http://jabber.org/protocol/si/profile/file-transfer
 * then this means someone has initiated a file transfer. We need to respond back with a negotiation response telling the
 * sender that we support http://jabber.org/protocol/bytestreams. Finally, we receive the file with a SOCKS5 socket.
 *
 * It's the other way around when we are the initiator. We send the request by calling initiateFileTransferTo:withData
 * and then wait for the iq result with the si namespace of http://jabber.org/protocol/si, send a disco#info response,
 * open a SOCKS5 socket and then wait for the other side the connect to start the transfer.
**/
- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)inIq
{
    NSString *type = [inIq type];
    // If the iq type is "set", then this means the other side has initiated the transfer.
    // This is because we are responding to the other side's "set" request.
    if ([@"set" isEqualToString:type]) {
        NSXMLElement *si = [inIq elementForName:@"si"];
        if (si != nil) {
            if ([@"http://jabber.org/protocol/si" isEqualToString:[si xmlns]]) {
                NSXMLElement *file = [si elementForName:@"file"];
                if ([@"http://jabber.org/protocol/si/profile/file-transfer" isEqualToString:[file xmlns]]) {
                    NSXMLElement *feature = [[inIq elementForName:@"si"] elementForName:@"feature"];
                    NSString *xmlns = [feature xmlns];
                    if ([@"http://jabber.org/protocol/feature-neg" isEqualToString:xmlns]) {
                        return [self sendNegotiationResponse:inIq];
                    }
                }
            }
        }
        else
        {
            NSXMLElement *query = [inIq elementForName:@"query"];
            if (query != nil)
            {
                if ([@"http://jabber.org/protocol/bytestreams" isEqualToString:[query xmlns]])
                {
                    NSString *querySid = [[query attributeForName:@"sid"] stringValue];
                    if ([sid isEqualToString:querySid]
                        && (mimeType == kXMPPSIFileTransferMimeTypePNG
                           || mimeType == kXMPPSIFileTransferMimeTypeGIF
                           || mimeType == kXMPPSIFileTransferMimeTypeJPG
                           || mimeType == kXMPPSIFileTransferMimeTypeMP3
                           || mimeType == kXMPPSIFileTransferMimeTypeOPUS))
                    {
                        state = kXMPPSIFileTransferStateReceiving;
                        turnSocket = [[TURNSocket alloc] initWithStream:xmppStream incomingTURNRequest:inIq];
                        [turnSocket startWithDelegate:self delegateQueue:dispatch_get_main_queue()];
                        return YES;
                    }
                    else
                    {
                        return [self sendStreamHostNegotiationError:inIq];
                    }
                }
            }
        }
    }
    // If the iq type is "result", this means the we have initiated the transfer
    else if ([@"result" isEqualToString:type]) {
        NSXMLElement *si = [inIq elementForName:@"si"];
        if (si != nil) {
            if ([@"http://jabber.org/protocol/si" isEqualToString:[si xmlns]]) {
                return [self handleServiceDiscoveryRequest:inIq];
            }
        }
    }
    
    return NO;
}


#pragma mark - TurnSocket delegates
- (void)turnSocket:(TURNSocket *)sender didSucceed:(GCDAsyncSocket *)socket {
	NSLog(@"TURN Connection succeeded! %@", socket);
	NSLog(@"You now have a socket that you can use to send/receive data to/from the other person.");

    [socket synchronouslySetDelegate:self delegateQueue:dispatch_get_main_queue()];

    if (state == kXMPPSIFileTransferStateSending) {
        [socket writeData:fileToSend withTimeout:60 tag:0];
    } else if (state == kXMPPSIFileTransferStateReceiving) {
        [socket readDataToLength:self.recvFileSize withTimeout:60 tag:0];
    }
}

- (void)turnSocketDidFail:(TURNSocket *)sender {
	NSLog(@"SOCKS5 Connection failed!");
    turnSocket = nil;
    state = kXMPPSIFileTransferStateNone;
}

#pragma mark - GCDAsyncSocket delegates
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSLog(@"FINISHED %lu", (unsigned long)[data length]);
    [sock disconnectAfterReading];
    state = kXMPPSIFileTransferStateNone;
    mimeType = kXMPPSIFileTransferMimeTypeNone;
    [multicastDelegate receivedData:data from:senderJID withMimeType:mimeType expectedFileName:recvFileName];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    NSLog(@"wrote data");
    [sock disconnectAfterWriting];
    state = kXMPPSIFileTransferStateNone;
    mimeType = kXMPPSIFileTransferMimeTypeNone;
}

- (void)socketDidCloseReadStream:(GCDAsyncSocket *)sock {
    NSLog(@"CLOSED");
    state = kXMPPSIFileTransferStateNone;
    mimeType = kXMPPSIFileTransferMimeTypeNone;
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    NSLog(@"SOCKS5 socket disconnected");
    turnSocket = nil;
    state = kXMPPSIFileTransferStateNone;
    mimeType = kXMPPSIFileTransferMimeTypeNone;
}



@end
