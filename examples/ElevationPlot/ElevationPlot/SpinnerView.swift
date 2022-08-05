//
//  SpinnerView.swift
//  ElevationPlot
//
//  Created by Steve Wainwright on 17/07/2022.
//

import UIKit

class SpinnerView: UIView {
    
    var spinner = UIActivityIndicatorView(style: .large)
    var label: UILabel?
    private var labelMessage: String?
    private var labelFont = UIFont(name: "Helvetica", size: 14)!
    
    var message: String {
        get { return labelMessage ?? "" }
        set {
            labelMessage = newValue
            if let _labelMessage = labelMessage {
                let height = _labelMessage.height(constraintedWidth: self.frame.width - 48, font: labelFont)
                initialiseLabel(width: self.frame.width - 48, height: height, labelMessage: _labelMessage)
            }
        }
    }
    
    var font: UIFont {
        get { return labelFont  }
        set {
            labelFont = newValue
            if let _labelMessage = labelMessage {
                let height = _labelMessage.height(constraintedWidth: self.frame.width - 48, font: labelFont)
                initialiseLabel(width: self.frame.width - 48, height: height, labelMessage: _labelMessage)
            }
        }
    }
    
    private func initialiseLabel(width: CGFloat, height: CGFloat, labelMessage: String) {
        //let height = labelMessage.height(constraintedWidth: width, font: labelFont)
        if label == nil {
            label = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: height))
        }
        if let _label = label {
            _label.translatesAutoresizingMaskIntoConstraints = false
            if !self.subviews.contains(_label) {
                self.addSubview(_label)
            }
            _label.addConstraints([NSLayoutConstraint(item: _label, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: width), NSLayoutConstraint(item: _label, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: height)])
            _label.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
            _label.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 40).isActive = true
            
            _label.numberOfLines = 0
            _label.text = labelMessage
            _label.font = self.labelFont
            _label.textAlignment = .center
        }
    }
    
    convenience init() {
        self.init(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        
        initCommon()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initCommon()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initCommon()
    }
    
    func initCommon() {
        self.backgroundColor = UIColor(white: 0, alpha: 0.7)

        self.spinner.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(self.spinner)
        
        self.spinner.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        self.spinner.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
    }
    
    override var isHidden: Bool {
            get {
                super.isHidden
            }
            set {
                super.isHidden = newValue
                if newValue {
                    self.spinner.stopAnimating()
                }
                else {
                    self.spinner.startAnimating()
                }
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

