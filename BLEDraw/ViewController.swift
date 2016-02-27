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
        
        self.drawView.startStroke(touch.locationInView(touch.view))
        
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
       
        let point = message.point()
       
        self.drawView.addPointToStroke(point, color: UIColor.redColor())
        
    }


}

