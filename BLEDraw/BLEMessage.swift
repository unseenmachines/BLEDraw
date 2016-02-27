//
//  BLEMessage.swift
//  BLEDraw
//
//  Created by Elliot Sinyor on 2016-02-27.
//  Copyright © 2016 elliotsinyor. All rights reserved.
//

import Foundation
import UIKit

enum MessageType : UInt8 {
    case unknown = 0x00
    case start = 0x01
    case point = 0x02
}

func messageTypeFromByte(byte: UInt8) -> MessageType {
   
    switch byte {
        
    case 0x01:
        return MessageType.start
    case 0x02:
        return MessageType.point
    default:
        return MessageType.unknown
    }
    
}

extension NSData {
   
    func firstByte() -> UInt8! {
        
        guard self.length > 0 else { return nil }
        
        var byte : UInt8 = 0x00
       
        let firstByte = self.subdataWithRange(NSRange(location: 0, length: 1))
       
        firstByte.getBytes(&byte, length: 1)
        
        return byte
    }
    
}


struct BLEMessage {
    
    let rawData : NSData! //includes the prefix byte and the message body
    let messageType : MessageType!
    
    init(type: MessageType, point: CGPoint) {
       
        let ptString : NSString = NSStringFromCGPoint(point)
        
        let data = NSMutableData(bytes: [type.rawValue], length: 1)
       
        data.appendData(ptString.dataUsingEncoding(NSUTF8StringEncoding)!)
     
        rawData = NSData(data: data)
        
        messageType = type
        
    }
    
    init(data: NSData) {
     
        messageType = messageTypeFromByte(data.firstByte() ?? 0x00)
        
        rawData = data
 
    }
   
    func point() -> CGPoint! {
       
        guard rawData != nil else { return nil }
       
        let ptString = String(data: rawData, encoding: NSUTF8StringEncoding)
        
        guard ptString != nil else { return nil }
      
        let point = CGPointFromString(ptString!)
       
        return point
        
    }
    
    
}
