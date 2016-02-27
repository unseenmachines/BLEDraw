//
//  BLEManager.swift
//  BLEDraw
//
//  Created by Elliot Sinyor on 2016-02-25.
//  Copyright © 2016 elliotsinyor. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol BLEManagerDelegate {
   
    func didReceiveMessage(message : BLEMessage)
    
}

class BLEManager : NSObject, CBPeripheralManagerDelegate, CBCentralManagerDelegate, CBPeripheralDelegate {

    static let sharedInstance = BLEManager()
   
    let peripheralManager = CBPeripheralManager()
    let centralManager = CBCentralManager()
    
    var drawCharacteristic : CBCharacteristic!
    
    var discoveredPeripherals : Set<CBPeripheral> = []
    var discoveredPeripheral : CBPeripheral!
    
    var delegate : BLEManagerDelegate!
   
    let numberofPointsPerPacket = 2
    var pointCounter = 0
  
    //Use one service + one characteristic for everything
    let serviceUUID = CBUUID(string: "404EA254-E72C-4D6F-BEB2-BD87BCE36141")
    let charactertisticUUID = CBUUID(string: "922D2EAF-45B0-4E89-A80F-66B2A4C04705")

      var characteristic : CBMutableCharacteristic = CBMutableCharacteristic(type: CBUUID(string: "922D2EAF-45B0-4E89-A80F-66B2A4C04705"), properties: [CBCharacteristicProperties.Write, CBCharacteristicProperties.Indicate], value: nil, permissions: CBAttributePermissions.Writeable)
    
    
    override init() {
        
        super.init()
        
        self.peripheralManager.delegate = self
        self.centralManager.delegate = self
        
    }
   
//# MARK: - Peripheral Manager methods
    
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
       
        if (peripheral.state == CBPeripheralManagerState.PoweredOn) {
         
            self.startPeripheralService()
           
            print("Starting peripheral service")
        }
        
    }
    
    func startPeripheralService() {
        
        let mutableChar = CBMutableCharacteristic(type: charactertisticUUID, properties: [CBCharacteristicProperties.Write, CBCharacteristicProperties.Indicate, CBCharacteristicProperties.Read], value: nil, permissions: CBAttributePermissions.Writeable)
        
        self.characteristic = mutableChar
        
        let mutableService = CBMutableService(type: serviceUUID, primary: true)
        
        mutableService.characteristics = [mutableChar]
        
        peripheralManager.removeAllServices()
        
        peripheralManager.addService(mutableService)
        
        peripheralManager.startAdvertising([CBAdvertisementDataLocalNameKey : "BLEDraw",
            CBAdvertisementDataServiceUUIDsKey : [serviceUUID]])
        
    }
    
   
    func peripheralManager(peripheral: CBPeripheralManager, didReceiveWriteRequests requests: [CBATTRequest]) {
        print("received write request: \(requests)")
      
        for request in requests {
            peripheral.respondToRequest(request, withResult: CBATTError.Success)
            if (request.characteristic.UUID == charactertisticUUID) {
               
                guard delegate != nil else {return }
                
                delegate.didReceiveMessage(BLEMessage(data: request.value!))
                
            }
        }
        
    }
    
    
//# MARK: - Central Manager methods
 
    func centralManagerDidUpdateState(central: CBCentralManager) {
       
        if (centralManager.state == CBCentralManagerState.PoweredOn) {
           
            self.startScanningForPeripherals()
            
        }
        
        
    }
    
    func startScanningForPeripherals() {
        print("Scanning for peripherals")
        //TODO: add dedicated serial queue for BT activity
        self.centralManager.scanForPeripheralsWithServices([serviceUUID], options: nil)
        
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        print("Discovered: \(advertisementData)")
      
        guard let discoveredUUIDS = advertisementData[CBAdvertisementDataServiceUUIDsKey] else {
            print("no advertisement data found")
            return
        }
    
        if (discoveredUUIDS[0] as! CBUUID == serviceUUID) {
            print("UUID is the same")
            discoveredPeripherals.insert(peripheral)
            discoveredPeripheral = peripheral
            peripheral.delegate = self
            centralManager.connectPeripheral(peripheral, options: nil)
        }
        
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        print("Connected to peripheral")
        peripheral.discoverServices([serviceUUID])
    }
    
  
//# MARK: Peripheral Delegate methods
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        
        guard peripheral.services != nil else { return }
        
        for service in peripheral.services! {
            if service.UUID == serviceUUID {
                peripheral.discoverCharacteristics([charactertisticUUID], forService: service)
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        
        guard service.characteristics != nil else {
            print("No characteristics found")
            return }
       
        for characteristic in service.characteristics! {
            if characteristic.UUID == charactertisticUUID {
                print("Discovered characteristic!")
                drawCharacteristic = characteristic
            }
        }
        
    }
    
    func sendToRemote(message : BLEMessage) {
       
        guard drawCharacteristic != nil else {
            print("No draw characteristic exists remotely")
            return
        }
        
        guard discoveredPeripheral != nil else {
            print("No peripheral exists")
            return
        }
      
        pointCounter += 1
        if (pointCounter == numberofPointsPerPacket || message.messageType == MessageType.start) {
            
            discoveredPeripheral.writeValue(message.rawData, forCharacteristic: drawCharacteristic, type: CBCharacteristicWriteType.WithResponse)
            pointCounter = 0
        }
        
    }
    
    
}
