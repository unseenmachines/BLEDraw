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
  
override func prefersStatusBarHidden() -> Bool {
    return false
}
   
//# MARK: Touch related methods
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        guard let touch = touches.first else { return }
        guard touch.view! == self.drawView else { return }
        
        let point = touch.normalizedLocationInView(touch.view)
      
        
    }
    
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
       
        guard let touch = touches.first else { return }
        guard touch.view! == self.drawView else { return }
        
        let point = touch.normalizedLocationInView(touch.view)
        
        
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
    }

    
//# MARK: BLEManager delegate methods
    
    func didReceiveMessage(message: BLEMessage) {
       
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

