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

/*
    The only VC in the project. Gets touchEvents via UIResponder methods and sends them to: 
        - The local drawView (via touchEventSignal)
        - The remote device (via touchEventSignal -> BLEManager)
*/
class ViewController: UIViewController, BLEManagerDelegate {

    @IBOutlet weak var drawView: DrawView!
    
    @IBOutlet weak var connectedLabel: UILabel!
    
    @IBAction func clearPressed() {
     
        touchEventObserver.sendNext(TouchEvent(point: CGPointZero, type: MessageType.clearPressed, source: .Local))
        
    }
    
    let bluetoothManager = BLEManager()
    
    //For some reason self.rac_signalForSelector doesn't seem to work, so make the signal like this
    let (touchEventSignal, touchEventObserver) = Signal<TouchEvent, NoError>.pipe()
   
    let (connectionStatusSignal, connectionStatusObserver) = Signal<Bool, NoError>.pipe()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bluetoothManager.delegate = self
        
        self.connectSignals()
        
    }
    
    func connectSignals() {
      
       
        connectionStatusSignal.observeNext({ isConnected in
            self.updateConnectionLabel(isConnected)
        })
      
        //This sends all (ie local and remote) touch events to the local drawView
        touchEventSignal.observeNext({ next in
            self.drawView.handleTouchEvent(next)
        })
        
        //This sends only local touch events to the remote device
        touchEventSignal
            .filter({ next in next.source == EventSource.Local})
            .observeNext({ next in
                //print("Sending \(next.type) message to remote")
                self.bluetoothManager.sendToRemote(BLEMessage(type: next.type, point: next.point))
                
            })
       
        
        /*
        touchEventSignal
            .map({ next -> TouchEvent in
                let xOffset : CGFloat = 0.03
                let yOffset : CGFloat = 0.03
                let newPoint = CGPointMake(next.point.x + xOffset, next.point.y + yOffset)
                return TouchEvent(point: newPoint, type: next.type, source: next.source)
            })
            .observeNext({ next in
                self.drawView.handleTouchEvent(next)
            })
        */
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
   
//# MARK: ViewController callbacks

override func viewDidLayoutSubviews() {
    self.drawView.handleDidLayoutSubviews()
}
  
override func prefersStatusBarHidden() -> Bool {
    return false
}
   
//# MARK: Touch related methods (UIResponder)
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
     
        guard let touchEvent = self.touchEventFromTouches(touches, type: MessageType.touchStarted) else { return }
      
        touchEventObserver.sendNext(touchEvent)
        
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
       
        guard let touchEvent = self.touchEventFromTouches(touches, type: MessageType.touchMoved) else { return }
        
        touchEventObserver.sendNext(touchEvent)
        
    }
    
//# MARK: BLEManager delegate methods
    
    func didReceiveMessage(message: BLEMessage) {
       
        touchEventObserver.sendNext(TouchEvent(point: message.point(), type: message.messageType, source: .Remote))
        
    }
    
    func connectionStateChanged(connected: Bool) {
     
        connectionStatusObserver.sendNext(connected)
    }
    
    func updateConnectionLabel(isConnected: Bool) {
       
        dispatch_async(dispatch_get_main_queue(), {
            self.connectedLabel.hidden = !isConnected
        })
    }
    

//# MARK Helper methods
    
    func touchEventFromTouches(touches: Set<UITouch>, type: MessageType) -> TouchEvent? {
        
        guard let touch = touches.first else { return nil }
        guard touch.view! == self.drawView else { return nil }
        
        let point = touch.normalizedLocationInView(touch.view)
        
        return TouchEvent(point: point, type: type, source:EventSource.Local)
        
    }


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

