//
//  DrawView.swift
//  BLEDraw
//
//  Created by Elliot Sinyor on 2016-02-26.
//  Copyright © 2016 elliotsinyor. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    
    func rgb() -> (red:CGFloat, green:CGFloat, blue:CGFloat, alpha:CGFloat)? {
        var fRed : CGFloat = 0
        var fGreen : CGFloat = 0
        var fBlue : CGFloat = 0
        var fAlpha: CGFloat = 0
        if self.getRed(&fRed, green: &fGreen, blue: &fBlue, alpha: &fAlpha) {
            return (red:fRed, green:fGreen, blue:fBlue, alpha:fAlpha)
        } else {
            // Could not extract RGBA components:
            return nil
        }
    }
}

class DrawView : UIView {
  
    //This holds the previously drawn point. The array holds 2 points, one for the local line (index 0) and one for the remote line (index 1)
    var previousPoints : [CGPoint!]! = [nil, nil]
   
    var mainImage : UIImageView!
    var incrementalImage : UIImageView!
    
    
    func denormalize(normalizedPoint : CGPoint) -> CGPoint {
       
        let denormalizedX = normalizedPoint.x * self.frame.width
        let denormalizedY = normalizedPoint.y * self.frame.height
        
        return CGPointMake(denormalizedX, denormalizedY)
        
    }
   
    func startStroke(normalizedPoint: CGPoint, lineIndex : Int) {
      
        previousPoints[lineIndex] = self.denormalize(normalizedPoint)
        
    }
    
    override func drawRect(rect: CGRect) {
        
    }
    
    func setupImageViews() {
     
        //If they have already been created, just adjust them
        if (mainImage != nil && incrementalImage != nil) {
            mainImage.frame = self.bounds
            incrementalImage.frame = self.bounds
            return
        }
        
        mainImage = UIImageView(frame: self.bounds)
        incrementalImage = UIImageView(frame: self.bounds)
        
        self.addSubview(mainImage)
        self.addSubview(incrementalImage)
        
        
    }

    
    func addPointToStroke(normalizedPoint: CGPoint, color: UIColor, lineIndex : Int) {
       
        if (previousPoints[lineIndex] == nil) {
            previousPoints[lineIndex] = self.denormalize(normalizedPoint)
        }
        
        let point = self.denormalize(normalizedPoint)
        
        UIGraphicsBeginImageContext(self.frame.size);
        self.incrementalImage.image?.drawInRect(CGRectMake(0, 0, self.frame.size.width, self.frame.size.height))
        
        let context = UIGraphicsGetCurrentContext()
        CGContextMoveToPoint(context, previousPoints[lineIndex].x, previousPoints[lineIndex].y);
        CGContextAddLineToPoint(context, point.x, point.y);
        CGContextSetLineCap(context, CGLineCap.Round);
        CGContextSetLineWidth(context, 2.0 );
        
      
        var components = color.rgb()
        
        if components == nil {
            components = (1.0, 1.0, 1.0, 1.0)
            
        }
        
        CGContextSetRGBStrokeColor(context, components!.0, components!.1, components!.2, 1.0);
        CGContextSetBlendMode(context, CGBlendMode.Normal);
        CGContextStrokePath(context);
        
        self.incrementalImage.image = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
       
        previousPoints[lineIndex] = point
        
    }
    
    func endStroke() {
       
        UIGraphicsBeginImageContext(self.mainImage.frame.size);
        
        self.mainImage.image?.drawInRect(CGRectMake(0, 0, self.frame.size.width, self.frame.size.height), blendMode: CGBlendMode.Normal, alpha:1.0)
        self.incrementalImage.image?.drawInRect(CGRectMake(0, 0, self.frame.size.width, self.frame.size.height), blendMode: CGBlendMode.Normal, alpha:1.0)
        
        self.mainImage.image = UIGraphicsGetImageFromCurrentImageContext();
        self.incrementalImage.image = nil
        
        UIGraphicsEndImageContext();
        
    }
    
    func clear() {
        self.mainImage.image = nil
    }
  
    
    
}
