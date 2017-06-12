//
//  AboutViewController.swift
//  TWU
//
//  Created by Steve Leeke on 8/6/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import UIKit
import MessageUI

extension AboutViewController : UIAdaptivePresentationControllerDelegate
{
    // MARK: UIAdaptivePresentationControllerDelegate
    
    // Specifically for Plus size iPhones.
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle
    {
        return UIModalPresentationStyle.none
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
}

extension AboutViewController : MFMailComposeViewControllerDelegate
{
    // MARK: MFMailComposeViewControllerDelegate Method
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}

extension AboutViewController : UIPopoverPresentationControllerDelegate
{
    
}

extension AboutViewController : PopoverTableViewControllerDelegate
{
    func rowClickedAtIndex(_ index: Int, strings: [String], purpose:PopoverPurpose, sermon:Sermon?) {
        dismiss(animated: true, completion: nil)
        
        switch purpose {
        case .selectingAction:
            switch strings[index] {
                
            case Constants.Email_TWU:
                email()
                break
                
            case Constants.TWU_Website:
                openWebSite(Constants.TWU.WEBSITE)
                break
                
            case Constants.Share_This_App:
                shareHTML(viewController: self,htmlString: Constants.TWU.APP + Constants.NEWLINE + Constants.NEWLINE + Constants.TWU.APP_URL)
                break
                
            default:
                break
            }
            break
            
        default:
            break
        }
    }
}

class AboutViewController : UIViewController
{
    @IBOutlet weak var versionLabel: UILabel!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    var frontView:UIView?
    
    @IBAction func give(_ sender: UIButton)
    {
        openWebSite(Constants.TWU.GIVING_URL)
    }
    
    @IBOutlet weak var actionsButton: UIBarButtonItem!
    
    @IBAction func twitter(_ sender: UIButton)
    {
        openWebSite("https://twitter.com/wordunleashed")
    }
    
    @IBAction func facebook(_ sender: UIButton)
    {
        openWebSite("https://www.facebook.com/TheWordUnleashed")
    }
    
    @IBAction func podcast(_ sender: UIButton)
    {
        openWebSite("https://itunes.apple.com/us/podcast/the-word-unleashed/id610499233?mt=2")
    }

    @IBAction func rssfeed(_ sender: UIButton)
    {
        openWebSite("http://www.thewordunleashed.org/podcast.php")
    }
    
    @IBAction func cbc(_ sender: UIButton)
    {
        openWebSite("http://www.countrysidebible.org/")
    }
    
    fileprivate func setVersion()
    {
        if let dict = Bundle.main.infoDictionary {
            if let appVersion = dict["CFBundleShortVersionString"] as? String {
                if let buildNumber = dict["CFBundleVersion"] as? String {
                    versionLabel.text = appVersion + "." + buildNumber
                    versionLabel.sizeToFit()
                }
            }
        }
    }
    
    override var canBecomeFirstResponder : Bool
    {
        return true
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?)
    {
        if let isCollapsed = splitViewController?.isCollapsed, isCollapsed {
            globals.motionEnded(motion, event: event)
        }
    }
    
    fileprivate func networkUnavailable(_ message:String?)
    {
        if (UIApplication.shared.applicationState == UIApplicationState.active) { //  && (self.view.window != nil)
            dismiss(animated: true, completion: nil)
            
            let alert = UIAlertController(title: Constants.Network_Error,
                message: message,
                preferredStyle: UIAlertControllerStyle.alert)
            
            let action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
                
            })
            alert.addAction(action)
            
            present(alert, animated: true, completion: nil)
        }
    }
    
    fileprivate func openWebSite(_ urlString:String)
    {
        if (UIApplication.shared.canOpenURL(URL(string:urlString)!)) { // Reachability.isConnectedToNetwork() &&
            UIApplication.shared.openURL(URL(string:urlString)!)
        } else {
            networkUnavailable("Unable to open web site: \(urlString)")
        }
    }

    fileprivate func showSendMailErrorAlert()
    {
        let sendMailErrorAlert = UIAlertView(title: "Could Not Send Email", message: "Your device could not send e-mail.  Please check your e-mail configuration and try again.", delegate: self, cancelButtonTitle: "OK")
        sendMailErrorAlert.show()
    }
    
    fileprivate func email()
    {
        let bodyString = String()
        
        //        bodyString = bodyString + addressStringHTML()
        
        let mailComposeViewController = MFMailComposeViewController()
        mailComposeViewController.mailComposeDelegate = self // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
        
        mailComposeViewController.setToRecipients([Constants.TWU.EMAIL])
        mailComposeViewController.setSubject(Constants.The_Word_Unleashed)
        //        mailComposeViewController.setMessageBody(bodyString, isHTML: false)
        mailComposeViewController.setMessageBody(bodyString, isHTML: true)
        
        if MFMailComposeViewController.canSendMail() {
            self.present(mailComposeViewController, animated: true, completion: nil)
        } else {
            self.showSendMailErrorAlert()
        }
    }
    
    @IBAction func actions(_ sender: UIBarButtonItem)
    {
        //In case we have one already showing
        dismiss(animated: true, completion: nil)
        
        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController {
            if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                navigationController.modalPresentationStyle = .popover
                //            popover?.preferredContentSize = CGSizeMake(300, 500)
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .up
                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
                
                //                popover.navigationItem.title = "Actions"
                
                popover.navigationController?.isNavigationBarHidden = true
                
                popover.delegate = self
                popover.purpose = .selectingAction
                
                var actionMenu = [String]()
                
                actionMenu.append(Constants.Email_TWU)
                actionMenu.append(Constants.TWU_Website)
                
                actionMenu.append(Constants.Share_This_App)
                
                popover.strings = actionMenu
                
                popover.showIndex = false //(globals.grouping == .series)
                popover.showSectionHeaders = false
                
                present(navigationController, animated: true, completion: nil)
            }
        }
    }
    
    var actionButton:UIBarButtonItem?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        actionButton = UIBarButtonItem(title: Constants.FA.ACTION, style: UIBarButtonItemStyle.plain, target: self, action: #selector(AboutViewController.actions))
        actionButton?.setTitleTextAttributes([NSFontAttributeName:UIFont(name: Constants.FA.name, size: Constants.FA.FONT_SIZE)!], for: UIControlState())
        
        self.navigationItem.rightBarButtonItem = actionButton
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        if self.navigationController?.visibleViewController == self {
            self.navigationController?.isToolbarHidden = true
            
            if  let hClass = self.splitViewController?.traitCollection.horizontalSizeClass,
                let vClass = self.splitViewController?.traitCollection.verticalSizeClass,
                let count = self.splitViewController?.viewControllers.count {
                if let navigationController = self.splitViewController?.viewControllers[count - 1] as? UINavigationController {
                    if (hClass == UIUserInterfaceSizeClass.regular) && (vClass == UIUserInterfaceSizeClass.compact) {
                        navigationController.topViewController?.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
                    } else {
                        navigationController.topViewController?.navigationItem.leftBarButtonItem = nil
                    }
                }
            }
        }
        
        setVersion()
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        scrollView.flashScrollIndicators()
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        globals.showingAbout = false
        
        NotificationCenter.default.removeObserver(self)
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)
        
        if (self.view.window == nil) {
            return
        }
        
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in

            }) { (UIViewControllerTransitionCoordinatorContext) -> Void in
                
                if self.navigationController?.visibleViewController == self {
                    self.navigationController?.isToolbarHidden = true
                    
                    if  let hClass = self.splitViewController?.traitCollection.horizontalSizeClass,
                        let vClass = self.splitViewController?.traitCollection.verticalSizeClass,
                        let count = self.splitViewController?.viewControllers.count {
                        if let navigationController = self.splitViewController?.viewControllers[count - 1] as? UINavigationController {
                            if (hClass == UIUserInterfaceSizeClass.regular) && (vClass == UIUserInterfaceSizeClass.compact) {
                                navigationController.topViewController?.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
                            } else {
                                navigationController.topViewController?.navigationItem.leftBarButtonItem = nil
                            }
                        }
                    }
                }
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
