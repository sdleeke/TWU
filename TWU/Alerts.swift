//
//  Alerts.swift
//  TWU
//
//  Created by Steve Leeke on 10/4/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit

class Alerts
{
    static var shared = Alerts()
 
    deinit {
        debug(self)
    }
    
    init()
    {
        Thread.onMain { [weak self] in
            self?.alertTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self?.alertViewer), userInfo: nil, repeats: true)
        }
    }
    
    @objc func alertViewer()
    {
        guard UIApplication.shared.applicationState == UIApplication.State.active else {
            return
        }
        
        guard alerts.count > 0, let alert = alerts.first else {
            return
        }
        
        let alertVC = UIAlertController(title:alert.title,
                                        message:alert.message,
                                        preferredStyle: UIAlertController.Style.alert)
        
        let action = UIAlertAction(title: Constants.Okay, style: UIAlertAction.Style.cancel, handler: { (UIAlertAction) -> Void in
            
        })
        alertVC.addAction(action)
        
        Thread.onMain { [weak self] in
            Globals.shared.splitViewController?.present(alertVC, animated: true, completion: {
                self?.alerts.remove(at: 0)
            })
        }
    }
    
    var alerts = [Alert]()
    
    var alertTimer : Timer?
    
    func alert(title:String,message:String?)
    {
        alerts.append(Alert(title: title, message: message))
    }
}
