//
//  SpinnerViewController.swift
//  ElevationPlot
//
//  Created by Steve Wainwright on 06/07/2022.
//

import UIKit

class SpinnerViewController: UIViewController {

    var spinner = UIActivityIndicatorView(style: .large)
    var label: UILabel?
    private var labelMessage: String?
    private var labelFont = UIFont(name: "Helvetica", size: 16)!
    
    var message: String {
        get { return labelMessage ?? "" }
        set {
            labelMessage = newValue
            if let _labelMessage = labelMessage {
                let height = _labelMessage.height(constraintedWidth: self.view.frame.width - 48, font: labelFont)
                initialiseLabel(width: self.view.frame.width - 48, height: height, labelMessage: _labelMessage)
            }
        }
    }
    
    override func loadView() {
        view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 0.7)

        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        view.addSubview(spinner)
        
        spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        if let _label = label {
            _label.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(_label)
            _label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            _label.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 30).isActive = true
        }
    }
    
    private func initialiseLabel(width: CGFloat, height: CGFloat, labelMessage: String) {
        //let height = labelMessage.height(constraintedWidth: width, font: labelFont)
        if label == nil {
            label = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: height))
        }
        if let _label = label {
            _label.translatesAutoresizingMaskIntoConstraints = false
            if !self.view.subviews.contains(_label) {
                self.view.addSubview(_label)
            }
            _label.addConstraints([NSLayoutConstraint(item: _label, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: width), NSLayoutConstraint(item: _label, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: height)])
            _label.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
            _label.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: 40).isActive = true
            
            _label.numberOfLines = 0
            _label.text = labelMessage
            _label.font = self.labelFont
            _label.textAlignment = .center
        }
    }
    
}

extension String {
    func height(constraintedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 0 // multiline
        label.font = font // your font
        label.lineBreakMode = .byWordWrapping
        label.preferredMaxLayoutWidth = width // max width
        label.text = self // the text to display in the label
        return label.intrinsicContentSize.height
    }
    
    func getLabelHeight(constraintedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let textAttributes = [NSAttributedString.Key.font: font]

        let rect = self.boundingRect(with: CGSize(width: width, height: 2000), options: .usesLineFragmentOrigin, attributes: textAttributes, context: nil)
        return rect.size.height
    }
}
