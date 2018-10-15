//  Created by Jonathan Galperin on 2015-07-07.
//  Original work Copyright (c) 2011 Ole Begemann. All rights reserved.
//  Modified Work Copyright (c) 2015 Edusight. All rights reserved.

import UIKit

class OBSlider: UISlider
{
	var scrubbingSpeed: Float = 0.0
	var realPositionValue: Float = 0.0
	var beganTrackingLocation: CGPoint?
	
	let scrubbingSpeedChangePositions = [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]
	
    let scrubbingSpeeds = [1.0, 0.5, 0.25, 0.125, 0.00625, 0.0]
	
	required init?(coder: NSCoder)
    {
		super.init(coder: coder)
        
        scrubbingSpeed = Float(scrubbingSpeeds[0])
	}
	
	override init(frame: CGRect)
    {
		super.init(frame: frame)
        
        scrubbingSpeed = Float(scrubbingSpeeds[0])
    }
    
	override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool
    {
        guard let view = superview?.superview else {
            return false
        }
        
		let beginTracking = super.beginTracking(touch, with: event)
		
		if beginTracking {
//			let thumbRect = thumbRectForBounds(bounds, trackRect: trackRectForBounds(bounds), value: value)
		
			realPositionValue = value
			beganTrackingLocation = CGPoint(x: touch.location(in: view).x, y: touch.location(in: view).y)
		}
		
		return beginTracking
	}
	
	override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool
    {
        guard let view = superview?.superview else {
            return false
        }
        
        guard let beganTrackingLocation = beganTrackingLocation else {
            return false
        }
        
		let previousLocation = touch.previousLocation(in: view)
		let currentLocation = touch.location(in: view)
		let trackingOffset = currentLocation.x - previousLocation.x // delta x
		
		let verticalOffset = fabs(currentLocation.y - beganTrackingLocation.y)/(view.bounds.height - beganTrackingLocation.y)
        
        var scrubbingSpeedChangePosIndex = indexOfLowerScrubbingSpeed(scrubbingSpeedChangePositions, forOffset: verticalOffset)
		
		if (scrubbingSpeedChangePosIndex == NSNotFound) {
			scrubbingSpeedChangePosIndex = scrubbingSpeeds.count
		}
        
        scrubbingSpeed = Float(scrubbingSpeeds[scrubbingSpeedChangePosIndex - 1])
        
		let trackRect: CGRect = self.trackRect(forBounds: bounds)
		
		realPositionValue = realPositionValue + (maximumValue - minimumValue) * Float(trackingOffset / trackRect.size.width)
		
		let valueAdjustment: Float = scrubbingSpeed * (maximumValue - minimumValue) * Float(trackingOffset / trackRect.size.width)
		
        let thumbAdjustment: Float = (realPositionValue - value) / Float(1 + fabs(currentLocation.y - beganTrackingLocation.y))

        value += valueAdjustment + thumbAdjustment
		
		if (isContinuous) {
			sendActions(for: UIControlEvents.valueChanged)
		}
		
		return isTracking
	}
	
	override func endTracking(_ touch: UITouch?, with event: UIEvent?)
    {
		if isTracking {
			scrubbingSpeed = 1.0
			sendActions(for: UIControlEvents.valueChanged)
		}
	}
	
	func indexOfLowerScrubbingSpeed(_ scrubbingSpeedPositions: Array<Double>, forOffset verticalOffset: CGFloat) -> Int
    {
		for i in 0..<scrubbingSpeedPositions.count {
            if verticalOffset < CGFloat(scrubbingSpeedPositions[i]) {
                return i
            }
		}
	
		return NSNotFound
	}
}
