//
//  ViewController.swift
//  BLEDraw
//
//  Created by Elliot Sinyor on 2016-02-25.
//  Copyright © 2016 elliotsinyor. All rights reserved.
//

import UIKit

class ViewController: UIViewController, BLEManagerDelegate {

    @IBOutlet weak var drawView: DrawView!
    
    @IBOutlet weak var connectedLabel: UILabel!
    @IBAction func clearPressed() {
       
        drawView.clear()
        
    }
    
    let bluetoothManager = BLEManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bluetoothManager.delegate = self
        
        self.updateConnectionLabel()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
   
//# MARK: Touch related methods
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        guard touch.view! == self.drawView else { return }
    
        let point = touch.locationInView(touch.view)
        
        self.drawView.startStroke(point)
      
        self.bluetoothManager.sendToRemote(BLEMessage(type: MessageType.start, point: point))
        
    }
    
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
       
        guard let touch = touches.first else { return }
       
        guard touch.view! == self.drawView else { return }
        
        //print("touches moved: \(touch.locationInView(touch.view))")
       
        let point = touch.locationInView(touch.view)
        
        self.drawView.addPointToStroke(point, color: UIColor.blackColor())
        
        self.bluetoothManager.sendToRemote(BLEMessage(type: MessageType.point, point: point))
        
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.drawView.endStroke()
    }
    
    
//# MARK: BLEManager delegate methods
    
    func didReceiveMessage(message: BLEMessage) {
       
        dispatch_async(dispatch_get_main_queue(), {
           
            if message.messageType == MessageType.point {
                
                self.drawView.addPointToStroke(message.point(), color: UIColor.redColor())
                
            } else if message.messageType == MessageType.start {
                
                self.drawView.startStroke(message.point())
                
            }
            
        })
        
        
        
    }
    
    func connectionStateChanged(connected: Bool) {
       
        self.updateConnectionLabel()
        
    }
    
    func updateConnectionLabel() {
       
        dispatch_async(dispatch_get_main_queue(), {
            if self.bluetoothManager.isConnected() {
                self.connectedLabel.hidden = false
            } else {
                self.connectedLabel.hidden = true
            }
        })
    }


}

