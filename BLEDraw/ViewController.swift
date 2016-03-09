//
//  ViewController.swift
//  BLEDraw
//
//  Created by Elliot Sinyor on 2016-02-25.
//  Copyright © 2016 elliotsinyor. All rights reserved.
//

import UIKit
import ReactiveCocoa
import enum Result.NoError

typealias NoError = Result.NoError

enum EventSource {
    case Remote
    case Local
}

struct TouchEvent {
   
    let point : CGPoint
    let type : MessageType
    let source : EventSource
    
}

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
  
    
    
    //For some reason self.rac_signalForSelector doesn't seem to work, so make the signal like this
    let (touchEventSignal, touchEventObserver) = Signal<TouchEvent, NoError>.pipe()
   
    let (connectionStatusSignal, connectionStatusObserver) = Signal<Bool, NoError>.pipe()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bluetoothManager.delegate = self
        
        self.updateConnectionLabel()
        self.connectSignals()
        
    }
    
    func connectSignals() {
      
        
        touchEventSignal.observeNext({ next in
            self.drawView.handleTouchEvent(next)
        })
        
        touchEventSignal
            .filter({ next in next.source == .Local})
            .observeNext({ next in
                //print("Sending \(next.type) message to remote")
                self.bluetoothManager.sendToRemote(BLEMessage(type: next.type, point: next.point))
                
            })
        
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
   
//# MARK: ViewController callbacks

override func viewDidLayoutSubviews() {
    self.drawView.setupImageViews()
}
  
override func prefersStatusBarHidden() -> Bool {
    return false
}
   
//# MARK: Touch related methods
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        guard let touch = touches.first else { return }
        guard touch.view! == self.drawView else { return }
        
        let point = touch.normalizedLocationInView(touch.view)
      
        touchEventObserver.sendNext(TouchEvent(point: point, type: MessageType.touchStarted, source: .Local))
        
    }
    
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
       
        guard let touch = touches.first else { return }
        guard touch.view! == self.drawView else { return }
        
        let point = touch.normalizedLocationInView(touch.view)
        
        touchEventObserver.sendNext(TouchEvent(point: point, type: MessageType.touchMoved, source: .Local))
        
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
       
        touchEventObserver.sendNext(TouchEvent(point: CGPointZero, type: MessageType.touchEnded, source: .Local))
        
    }

    
//# MARK: BLEManager delegate methods
    
    func didReceiveMessage(message: BLEMessage) {
       
        touchEventObserver.sendNext(TouchEvent(point: message.point(), type: message.messageType, source: .Remote))
        
    }
    
    func connectionStateChanged(connected: Bool) {
     
        connectionStatusObserver.sendNext(connected)
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

