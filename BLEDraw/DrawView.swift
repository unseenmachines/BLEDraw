//
//  DrawView.swift
//  BLEDraw
//
//  Created by Elliot Sinyor on 2016-02-26.
//  Copyright © 2016 elliotsinyor. All rights reserved.
//

import Foundation
import UIKit



class DrawView : UIView {
 
    //This holds the previous points
    var previousPoints : Dictionary<EventSource,CGPoint> = [EventSource.Local:CGPointZero, EventSource.Remote:CGPointZero]
    
    let lineColours : Dictionary<EventSource, UIColor> = [.Local:UIColor.redColor(), .Remote:UIColor.blackColor()]
   
    var imageView : UIImageView!
    
    private func setupImageViews() {
        
        //If the view already exists, just adjust it to the possibly new bound (eg during rotation)
        if (imageView != nil) {
            imageView.frame = self.bounds
            return
        }
        
        imageView = UIImageView(frame: self.bounds)
        
        self.addSubview(imageView)
        
    }
    
    
    //All drawing should happen through this method
    func handleTouchEvent(event: TouchEvent) {
     
        dispatch_async(dispatch_get_main_queue(), {
        
            switch event.type {
                
            case .touchStarted:
                self.startStroke(event.point, source: event.source)
                break
                
            case .touchMoved:
                self.addPointToStroke(event.point, color: self.lineColours[event.source]!, source: event.source)
                break
                
            case .clearPressed:
                self.clear()
                break
                
            default:
                break
                
            }
        
        })
        
    }

    //Called by hosting VC
    func handleDidLayoutSubviews() {
        setupImageViews()
    }
    
    private func startStroke(normalizedPoint: CGPoint, source : EventSource) {
        
        previousPoints[source] = self.denormalize(normalizedPoint)
        
    }
    
    private func addPointToStroke(normalizedPoint: CGPoint, color: UIColor, source : EventSource) {

        let point = self.denormalize(normalizedPoint)
        
        UIGraphicsBeginImageContext(self.frame.size);
        self.imageView.image?.drawInRect(CGRectMake(0, 0, self.frame.size.width, self.frame.size.height))
        
        let context = UIGraphicsGetCurrentContext()
        CGContextMoveToPoint(context, previousPoints[source]!.x, previousPoints[source]!.y);
        CGContextAddLineToPoint(context, point.x, point.y);
        CGContextSetLineCap(context, CGLineCap.Round);
        CGContextSetLineWidth(context, 2.0 );
      
        let components = color.rgb()
        CGContextSetRGBStrokeColor(context, components.0, components.1, components.2, 1.0);
        CGContextSetBlendMode(context, CGBlendMode.Normal);
        CGContextStrokePath(context);
        
        self.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
       
        previousPoints[source] = point
        
    }
    
    
    private func clear() {
        self.imageView.image = nil
    }
  
    //Helper method to denormalize point to local frame size
    private func denormalize(normalizedPoint : CGPoint) -> CGPoint {
        
        let denormalizedX = normalizedPoint.x * self.frame.width
        let denormalizedY = normalizedPoint.y * self.frame.height
        
        return CGPointMake(denormalizedX, denormalizedY)
        
    }
    
    
}

//# MARK: Helpers

extension UIColor {
    
    func rgb() -> (red:CGFloat, green:CGFloat, blue:CGFloat, alpha:CGFloat) {
        var fRed : CGFloat = 0
        var fGreen : CGFloat = 0
        var fBlue : CGFloat = 0
        var fAlpha: CGFloat = 0
        if self.getRed(&fRed, green: &fGreen, blue: &fBlue, alpha: &fAlpha) {
            return (red:fRed, green:fGreen, blue:fBlue, alpha:fAlpha)
        } else {
            // Could not extract RGBA components:
            return (red: 0, green: 0, blue: 0, alpha: 0)
        }
    }
}

