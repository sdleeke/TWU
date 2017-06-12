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
    
	override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
		let beginTracking = super.beginTracking(touch, with: event)
		
		if (beginTracking) {
//			let thumbRect = self.thumbRectForBounds(self.bounds, trackRect: self.trackRectForBounds(self.bounds), value: self.value)
		
			self.realPositionValue = self.value
			self.beganTrackingLocation = CGPoint(x: touch.location(in: self.superview).x, y: touch.location(in: self.superview).y)
		}
		
		return beginTracking
	}
	
	override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
		let previousLocation = touch.previousLocation(in: self.superview)
		let currentLocation = touch.location(in: self.superview)
		let trackingOffset = currentLocation.x - previousLocation.x // delta x
		
		let verticalOffset = fabs(currentLocation.y - beganTrackingLocation!.y)/(self.superview!.bounds.height - beganTrackingLocation!.y)
//        print("verticalOffset: \(CGFloat(verticalOffset))")
        
        var scrubbingSpeedChangePosIndex: NSInteger = self.indexOfLowerScrubbingSpeed(scrubbingSpeedChangePositions, forOffset: verticalOffset)
		
		if (scrubbingSpeedChangePosIndex == NSNotFound) {
			scrubbingSpeedChangePosIndex = self.scrubbingSpeeds.count
		}
		self.scrubbingSpeed = Float(self.scrubbingSpeeds[scrubbingSpeedChangePosIndex - 1] as! NSNumber)
//        print("scrubbingSpeed: \(self.scrubbingSpeed)")
		
		let trackRect: CGRect = self.trackRect(forBounds: self.bounds)
		
		self.realPositionValue = self.realPositionValue + (self.maximumValue - self.minimumValue) * Float(trackingOffset / trackRect.size.width)
		
		let valueAdjustment: Float = self.scrubbingSpeed * (self.maximumValue - self.minimumValue) * Float(trackingOffset / trackRect.size.width)
		
//        print("valueAdjustment: \(valueAdjustment)")
		
		var thumbAdjustment: Float = 0.0
		
		if (((self.beganTrackingLocation!.y < currentLocation.y) && (currentLocation.y < previousLocation.y)) || ((self.beganTrackingLocation!.y > currentLocation.y) && (currentLocation.y > previousLocation.y))) {
			
			thumbAdjustment = (self.realPositionValue - self.value) / Float(1 + fabs(currentLocation.y - self.beganTrackingLocation!.y))
		}
		
//        print("thumbAdjustment: \(thumbAdjustment)")

        self.value += valueAdjustment + thumbAdjustment
		
		if (self.isContinuous) {
			self.sendActions(for: UIControlEvents.valueChanged)
		}
		
		return self.isTracking
	}
	
	override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
		if (self.isTracking) {
			self.scrubbingSpeed = 1.0
			self.sendActions(for: UIControlEvents.valueChanged)
		}
	}
	
	func indexOfLowerScrubbingSpeed (_ scrubbingSpeedPositions: NSArray, forOffset verticalOffset: CGFloat) -> NSInteger {
		for i in 0..<scrubbingSpeedPositions.count {
			let scrubbingSpeedOffset: NSNumber = scrubbingSpeedPositions[i] as! NSNumber
//            print("indexOfLowerScrubbingSpeed: \(CGFloat(scrubbingSpeedOffset))")
			if (verticalOffset < CGFloat(scrubbingSpeedOffset)) {
				return i
			}
		}
	
		return NSNotFound
	}
}
