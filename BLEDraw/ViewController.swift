//
//  ViewController.swift
//  BLEDraw
//
//  Created by Elliot Sinyor on 2016-02-25.
//  Copyright © 2016 elliotsinyor. All rights reserved.
//

import UIKit


extension UITouch {
   
   
    func normalizedLocationInView(view : UIView?) -> CGPoint {
       
        guard view != nil else  { return CGPointMake(0, 0) }
      
        let point = self.locationInView(view)
       
        let normalizedX = point.x / view!.frame.size.width
        let normalizedY = point.y / view!.frame.size.height
        
        return CGPointMake(normalizedX, normalizedY)
    }
    
}

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
   
//# MARK: ViewController callbacks

override func viewDidLayoutSubviews() {
    self.drawView.setupImageViews()
}
    
   
//# MARK: Touch related methods
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        guard let touch = touches.first else { return }
        
        guard touch.view! == self.drawView else { return }
        
        let point = touch.normalizedLocationInView(touch.view)
        
        self.drawView.startStroke(point)
      
        self.bluetoothManager.sendToRemote(BLEMessage(type: MessageType.touchStarted, point: point))
        
    }
    
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
       
        guard let touch = touches.first else { return }
       
        guard touch.view! == self.drawView else { return }
        
        let point = touch.normalizedLocationInView(touch.view)
        
        self.drawView.addPointToStroke(point, color: UIColor.blackColor())
        
        self.bluetoothManager.sendToRemote(BLEMessage(type: MessageType.touchMoved, point: point))
        
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        self.drawView.endStroke()
        
        self.bluetoothManager.sendToRemote(BLEMessage(type: MessageType.touchEnded))
    }

    
//# MARK: BLEManager delegate methods
    
    func didReceiveMessage(message: BLEMessage) {
       
        dispatch_async(dispatch_get_main_queue(), {
           
            if message.messageType == MessageType.touchMoved {
                
                self.drawView.addPointToStroke(message.point(), color: UIColor.redColor())
                
            } else if message.messageType == MessageType.touchStarted {
                
                self.drawView.startStroke(message.point())
                
            } else if message.messageType == MessageType.touchEnded {
                
                self.drawView.endStroke()
                
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

