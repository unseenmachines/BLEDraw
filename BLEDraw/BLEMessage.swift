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
