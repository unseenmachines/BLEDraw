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
        
        self.drawView.addPointToStroke(touch.locationInView(touch.view), color: UIColor.blackColor())
        
        let ptString : NSString = NSStringFromCGPoint(touch.locationInView(touch.view))
        
        let ptData = ptString.dataUsingEncoding(NSUTF8StringEncoding)
        
        self.bluetoothManager.sendToRemote(ptData!)
        
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.drawView.endStroke()
    }
    
    func didReceivePoint(point: NSData) {
       
        let ptString = String(data: point, encoding: NSUTF8StringEncoding)
       
        let point = CGPointFromString(ptString!)
       
        self.drawView.addPointToStroke(point, color: UIColor.redColor())
        
    }


}

