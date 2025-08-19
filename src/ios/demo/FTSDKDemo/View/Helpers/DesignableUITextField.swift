//
//  DesignableUITextField.swift
//  FTSDKDemo
//
//  Created by hulilei on 2023/7/18.
//

import UIKit
import CoreGraphics
class DesignableUITextField: UITextField {
    var leftPadding: CGFloat = 10
    var leftImage: UIImage? {
        didSet {
            updateView()
        }
    }
    var color: UIColor = .icon {
        didSet {
            updateView()
        }
    }
    var lineColor: UIColor = .darkGray {
        didSet {
            if lineColor != oldValue {
                self.setNeedsDisplay()
            }
        }
    }
    var isPassword: Bool = false {
        didSet{
            updateView()
        }
    }
    var eyeBtn:UIButton?
    var connect: ConnectStatus = .normal {
        willSet {
            switch newValue {
            case .normal:
                self.textColor = .darkGray
            case .success:
                self.textColor = .systemGreen
            case .error:
                self.textColor = .systemRed
            }
        }
    }
    override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        var textRect = super.leftViewRect(forBounds: bounds)
        textRect.size.width += leftPadding
        return textRect
    }
    override func clearButtonRect(forBounds bounds: CGRect) -> CGRect {
        var btnRect = super.clearButtonRect(forBounds: bounds)
        if isPassword {
            btnRect.origin.x = bounds.origin.x + bounds.size.width - 55
        }
        return btnRect
    }
    func updateView() {
        if let image = leftImage {
            leftViewMode = UITextField.ViewMode.always
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 25))
            imageView.contentMode = .scaleAspectFit
            imageView.image = image
            imageView.tintColor = .icon
            leftView = imageView
        } else {
            leftViewMode = UITextField.ViewMode.never
            leftView = nil
        }
        if isPassword {
            eyeBtn = UIButton.init()
            eyeBtn!.addTarget(self, action: #selector(eyeClick), for: .touchUpInside)
            eyeBtn!.setImage(UIImage(systemName: "eye.slash"), for: .normal)
            eyeBtn!.tintColor = color
            self.addSubview(eyeBtn!)
            
        }
        // Placeholder text color
        attributedPlaceholder = NSAttributedString(string: placeholder != nil ?  placeholder! : "", attributes:[NSAttributedString.Key.foregroundColor: color])
    }
    @objc func eyeClick(){
        isSecureTextEntry = !isSecureTextEntry
        if isSecureTextEntry {
            eyeBtn!.setImage(UIImage(systemName: "eye.slash"), for: .normal)
            
        }else{
            eyeBtn!.setImage(UIImage(systemName: "eye"), for: .normal)
        }
    }
    override func draw(_ rect: CGRect) {
        let lineHeight:CGFloat = 0.5
        let lineColor:UIColor = lineColor
        
        guard let content = UIGraphicsGetCurrentContext() else{return}
        
        content.setFillColor(lineColor.cgColor)
        content.fill(CGRect(x: 0, y: self.frame.height-lineHeight, width: self.frame.width, height: lineHeight))
        UIGraphicsBeginImageContextWithOptions(rect.size, true, 0)
        if let eyeBtn = eyeBtn {
            eyeBtn.frame = CGRect(x: rect.origin.x + rect.size.width - 30, y: rect.origin.y, width: 30, height: rect.size.height)
        }
    }
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
    
}
public extension UIImage {
    convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}
