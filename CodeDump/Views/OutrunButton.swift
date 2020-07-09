//
//  OutrunButton.swift
//  CodeDump
//
//  Created by Luke Solomon on 7/8/20.
//  Copyright © 2020 Observatory. All rights reserved.
//

import UIKit

class OutrunButton: UIButton {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
  
  
  func customize(text: String, font:OutrunFonts, size: CGFloat, textColor: UIColor) {
    self.backgroundColor = UIColor.OutrunBlack
    
//    self.titleLabel?.text = text
//    self.titleLabel?.font = UIFont(name: font.rawValue, size: size) ?? UIFont.systemFont(ofSize: size)
//    self.titleLabel?.textColor = textColor
    
    self.setAttributedTitle(NSAttributedString(string: text, attributes: [
      .foregroundColor : textColor,
      .font : UIFont(name: font.rawValue, size: size) ?? UIFont.systemFont(ofSize: size)
    ]), for: .normal)
    
    self.layer.cornerRadius = CGFloat(10)
  }

}
