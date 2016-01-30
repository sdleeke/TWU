//  Created by Jonathan Galperin on 2015-07-07.
//  Original work Copyright (c) 2011 Ole Begemann. All rights reserved.
//  Modified Work Copyright (c) 2015 Edusight. All rights reserved.

import UIKit

class OBSlider: UISlider {
	
	var scrubbingSpeed: Float = 0.0
	var realPositionValue: Float = 0.0
	var beganTrackingLocation: CGPoint?
	
	var scrubbingSpeedChangePositions: NSArray = [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]
	
    var scrubbingSpeeds: NSArray = [1.0, 0.5, 0.25, 0.125, 0.00625, 0.0]
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		self.scrubbingSpeed = Float(self.scrubbingSpeeds[0] as! NSNumber)
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		self.scrubbingSpeed = Float(self.scrubbingSpeeds[0] as! NSNumber)
	}
    
	override func beginTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
		let beginTracking = super.beginTrackingWithTouch(touch, withEvent: event)
		
		if (beginTracking) {
//			let thumbRect = self.thumbRectForBounds(self.bounds, trackRect: self.trackRectForBounds(self.bounds), value: self.value)
		
			self.realPositionValue = self.value
			self.beganTrackingLocation = CGPointMake(touch.locationInView(self.superview).x, touch.locationInView(self.superview).y)
		}
		
		return beginTracking
	}
	
	override func continueTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
		let previousLocation = touch.previousLocationInView(self.superview)
		let currentLocation = touch.locationInView(self.superview)
		let trackingOffset = currentLocation.x - previousLocation.x // delta x
		
		let verticalOffset = fabs(currentLocation.y - beganTrackingLocation!.y)/(self.superview!.bounds.height - beganTrackingLocation!.y)
        print("verticalOffset: \(CGFloat(verticalOffset))")
        
        var scrubbingSpeedChangePosIndex: NSInteger = self.indexOfLowerScrubbingSpeed(scrubbingSpeedChangePositions, forOffset: verticalOffset)
		
		if (scrubbingSpeedChangePosIndex == NSNotFound) {
			scrubbingSpeedChangePosIndex = self.scrubbingSpeeds.count
		}
		self.scrubbingSpeed = Float(self.scrubbingSpeeds[scrubbingSpeedChangePosIndex - 1] as! NSNumber)
//        print("scrubbingSpeed: \(self.scrubbingSpeed)")
		
		let trackRect: CGRect = self.trackRectForBounds(self.bounds)
		
		self.realPositionValue = self.realPositionValue + (self.maximumValue - self.minimumValue) * Float(trackingOffset / trackRect.size.width)
		
		let valueAdjustment: Float = self.scrubbingSpeed * (self.maximumValue - self.minimumValue) * Float(trackingOffset / trackRect.size.width)
		
//        print("valueAdjustment: \(valueAdjustment)")
		
		var thumbAdjustment: Float = 0.0
		
		if (((self.beganTrackingLocation!.y < currentLocation.y) && (currentLocation.y < previousLocation.y)) || ((self.beganTrackingLocation!.y > currentLocation.y) && (currentLocation.y > previousLocation.y))) {
			
			thumbAdjustment = (self.realPositionValue - self.value) / Float(1 + fabs(currentLocation.y - self.beganTrackingLocation!.y))
		}
		
//        print("thumbAdjustment: \(thumbAdjustment)")

        self.value += valueAdjustment + thumbAdjustment
		
		if (self.continuous) {
			self.sendActionsForControlEvents(UIControlEvents.ValueChanged)
		}
		
		return self.tracking
	}
	
	override func endTrackingWithTouch(touch: UITouch?, withEvent event: UIEvent?) {
		if (self.tracking) {
			self.scrubbingSpeed = 1.0
			self.sendActionsForControlEvents(UIControlEvents.ValueChanged)
		}
	}
	
	func indexOfLowerScrubbingSpeed (scrubbingSpeedPositions: NSArray, forOffset verticalOffset: CGFloat) -> NSInteger {
		for (var i = 0; i < scrubbingSpeedPositions.count; i++) {
			let scrubbingSpeedOffset: NSNumber = scrubbingSpeedPositions[i] as! NSNumber
//            print("indexOfLowerScrubbingSpeed: \(CGFloat(scrubbingSpeedOffset))")
			if (verticalOffset < CGFloat(scrubbingSpeedOffset)) {
				return i
			}
		}
	
		return NSNotFound
	}
}
