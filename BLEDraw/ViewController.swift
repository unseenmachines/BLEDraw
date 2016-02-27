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
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
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
    
    func didReceiveMessage(message: BLEMessage) {
        
        if message.messageType == MessageType.point {
            
            self.drawView.addPointToStroke(message.point(), color: UIColor.redColor())

        } else if message.messageType == MessageType.start {
           
            self.drawView.startStroke(message.point())
            
        }
        
        
    }


}

