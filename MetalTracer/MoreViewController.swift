//
//  MoreViewController.swift
//  MetalTracer
//
//  Created by Ingebretsen, Andrew (HBO) on 3/27/18.
//  Copyright © 2018 Drew Ingebretsen. All rights reserved.
//

import UIKit
import MessageUI

class MoreViewController: UIViewController, MFMailComposeViewControllerDelegate {
    
    weak var raytracerView: RaytracerView!
    
    @IBAction func showFeedback(_ sender: AnyObject) {
        if !MFMailComposeViewController.canSendMail() {
            return
        }
        
        let composeVC = MFMailComposeViewController()
        composeVC.mailComposeDelegate = self
        
        composeVC.setToRecipients(["drew@thinkpeopletech.com"])
        composeVC.setSubject("Real Time Path Tracer Feedback v1.2")
        
        parent?.present(composeVC, animated: true, completion: nil)
    }
    
    @IBAction func showInformation(_ sender: Any) {
        let infoViewController = (storyboard?.instantiateViewController(withIdentifier: "InfoViewController"))!
        parent?.present(infoViewController, animated: true, completion: nil)
    }
    
    @IBAction func saveImage(_ sender: AnyObject) {
        let image:UIImage = raytracerView.currentImage!
        UIGraphicsBeginImageContext(image.size);
        UIGraphicsGetCurrentContext()?.draw(image.cgImage!, in: CGRect(x: 0.0,y: 0.0, width: image.size.width, height: image.size.height));
        let flippedImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!;
        UIGraphicsEndImageContext();
        let sharingItems:[AnyObject] = [flippedImage]
        
        let activityViewController = UIActivityViewController(activityItems: sharingItems, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = sender as? UIView
        parent?.present(activityViewController, animated: true, completion: nil)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
