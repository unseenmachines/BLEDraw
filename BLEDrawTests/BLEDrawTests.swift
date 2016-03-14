//
//  BLEDrawTests.swift
//  BLEDrawTests
//
//  Created by Elliot Sinyor on 2016-02-25.
//  Copyright © 2016 elliotsinyor. All rights reserved.
//

import XCTest
@testable import BLEDraw

import UIKit

class BLEDrawTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testMessageFromPoint() {
    
        let point = CGPointMake(196.5, 71.5)
       
        let message = BLEMessage(type: MessageType.touchMoved, point: point)
       
        let bytes : [UInt8] = [0x02, 0x7b, 0x31, 0x39, 0x36, 0x2e, 0x35, 0x2c, 0x20, 0x37, 0x31, 0x2e, 0x35, 0x7d]
        let data : NSData = NSData(bytes: bytes, length: bytes.count)
     
        print("message from point: \(message.rawData)")
        print("data from other conversion: \(data)")
        
        XCTAssert(message.rawData.isEqualToData(data), "The messages don't match")
        
        XCTAssert(message.point() == point, "The extracted point doesn't match the input point")
       
    }
    
    func testMessageFromData() {
        
        let bytes : [UInt8] = [0x02, 0x7b, 0x31, 0x39, 0x36, 0x2e, 0x35, 0x2c, 0x20, 0x37, 0x31, 0x2e, 0x35, 0x7d]
        let data : NSData = NSData(bytes: bytes, length: bytes.count)
       
        let message = BLEMessage(data: data)
        
        XCTAssert(message.rawData.isEqualToData(data), "The extracted raw data doesn't match the input data")
        
        XCTAssert(message.messageType == MessageType.touchMoved, "The extracted message type doesn't match the input data")
       
        let point = CGPointMake(196.5, 71.5)
        
        XCTAssert(message.point() == point, "The extracted point doesn't match the input point")
        
        
    }
    
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
