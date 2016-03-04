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
    func connectionStateChanged(connected : Bool)
    
}

class BLEManager : NSObject, CBPeripheralManagerDelegate, CBCentralManagerDelegate, CBPeripheralDelegate {

    static let sharedInstance = BLEManager()
   
    var peripheralManager : CBPeripheralManager!
    var centralManager : CBCentralManager!
    
    var drawCharacteristic : CBCharacteristic!
    
    var discoveredPeripherals : Set<CBPeripheral> = []
    var discoveredPeripheral : CBPeripheral!
    
    var delegate : BLEManagerDelegate!
   
    let numberofPointsPerPacket = 2
    var pointCounter = 0
 
    let bluetoothQueue = dispatch_queue_create("com.elliotsinyor.blequeue", DISPATCH_QUEUE_SERIAL);
  
    //Use one service + one characteristic for everything
    let serviceUUID = CBUUID(string: "404EA254-E72C-4D6F-BEB2-BD87BCE36141")
    let charactertisticUUID = CBUUID(string: "922D2EAF-45B0-4E89-A80F-66B2A4C04705")

    var characteristic : CBMutableCharacteristic!
    
    override init() {
        
        super.init()
       
        self.centralManager = CBCentralManager(delegate: self, queue: bluetoothQueue)
       
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: bluetoothQueue)
        
        
    }
    
//# MARK: - Basic Methods
    
    func isConnected() -> Bool {
       
        if self.drawCharacteristic != nil {
            return true
        } else {
            return false
        }
        
    }
    
    func handleDisconnection() {
        self.stopPeripheralService()
       
        self.drawCharacteristic = nil
        self.discoveredPeripheral = nil
        
        self.delegate?.connectionStateChanged(self.isConnected())
        
        if (self.peripheralManager.state == CBPeripheralManagerState.PoweredOn) {
           
            self.startPeripheralService()
            
            self.startScanningForPeripherals()
        }
        
    }
   
//# MARK: - Peripheral Manager methods
    
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
       
        if (peripheral.state == CBPeripheralManagerState.PoweredOn) {
         
            self.startPeripheralService()
           
            print("Starting peripheral service")
        } else if (peripheral.state == CBPeripheralManagerState.PoweredOff) {
            
            self.handleDisconnection()
        }
        
    }
    
    func startPeripheralService() {
        
        let mutableChar = CBMutableCharacteristic(type: charactertisticUUID, properties: [CBCharacteristicProperties.Write, CBCharacteristicProperties.WriteWithoutResponse, CBCharacteristicProperties.Indicate, CBCharacteristicProperties.Read], value: nil, permissions: CBAttributePermissions.Writeable)
        
        self.characteristic = mutableChar
        
        let mutableService = CBMutableService(type: serviceUUID, primary: true)
        
        mutableService.characteristics = [mutableChar]
        
        peripheralManager.removeAllServices()
        
        peripheralManager.addService(mutableService)
        
        peripheralManager.startAdvertising([CBAdvertisementDataLocalNameKey : "BLEDraw",
            CBAdvertisementDataServiceUUIDsKey : [serviceUUID]])
        
    }
    
    func stopPeripheralService() {
        
        peripheralManager.stopAdvertising()
        
        peripheralManager.removeAllServices()
        
        self.characteristic = nil
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
            
        } else if (centralManager.state == CBCentralManagerState.PoweredOff) {
            
            self.handleDisconnection()
            
        }
        
    }
    
    func startScanningForPeripherals() {
        print("Scanning for peripherals")
        //TODO: add dedicated serial queue for BT activity
        
        self.centralManager.stopScan()
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
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
      
        if (peripheral.isEqual(self.discoveredPeripheral)) {
           
            self.handleDisconnection()
   
        }
        
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
                
                self.delegate.connectionStateChanged(self.isConnected())
                
                peripheral.setNotifyValue(true, forCharacteristic: characteristic)
            }
        }
        
    }
   
    func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFromCharacteristic characteristic: CBCharacteristic) {
        print("Central unsubscribed")
        self.handleDisconnection()
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
