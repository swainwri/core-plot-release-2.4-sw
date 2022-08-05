//
//  PopoverPresentationExtension.swift
//  ElevationPlot
//
//  Created by Steve Wainwright on 02/08/2022.
//

import UIKit

protocol PopoverPresentationSourceView {}
extension UIBarButtonItem : PopoverPresentationSourceView {}
extension UIView : PopoverPresentationSourceView {}

extension UIPopoverPresentationControllerDelegate where Self : UIViewController {
   
    func present(popover: UIViewController, from sourceView: PopoverPresentationSourceView, size: CGSize, arrowDirection: UIPopoverArrowDirection) {

        popover.modalPresentationStyle = .popover
        popover.preferredContentSize = size
        let popoverController = popover.popoverPresentationController
        popoverController?.delegate = self
        if let aView = sourceView as? UIView {
            popoverController?.sourceView = aView
//            let point = self.view.location(in: aView)
//            //set a sourceRect which is guranteed to be inside the device bounds when the colorView exceeds the devie bounds
//            if ( self.view.bounds.size.width - aView.frame.width) < 0 || ( self.view..bounds.size.height - aView.frame.height) < 0 {
//                popoverController?.sourceRect = CGRect(origin: point, size: CGSize(width: 1, height: 1))
//            }
//            else {
                popoverController?.sourceRect = aView.bounds
//            }
        }
        else if let barButtonItem = sourceView as? UIBarButtonItem {
            popoverController?.barButtonItem = barButtonItem
        }
        popoverController?.permittedArrowDirections = arrowDirection
        present(popover, animated: true, completion: nil)
   }
    
}
