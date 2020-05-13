//
//  OutrunLabel.swift
//  CodeDump
//
//  Created by Luke Solomon on 5/11/20.
//  Copyright © 2020 Observatory. All rights reserved.
//

import UIKit

//    for family in UIFont.familyNames.sorted() {
//        let names = UIFont.fontNames(forFamilyName: family)
//        print("Family: \(family) Font names: \(names)")
//    }
//
//    guard let customFont = UIFont(name: "Mozart", size: UIFont.labelFontSize) else {
//        fatalError("""
//            Failed to load the "Mozart" font.
//            Make sure the font file is included in the project and the font name is spelled correctly.
//            """
//        )
//    }

enum OutrunFonts:String {
  case Pixel = "Pixel-01"
  case Future = "OutrunFuture"
  case MorningStar = "MorningStar"
}

class OutrunLabel:UILabel {
  
  func customize(text: String, font:OutrunFonts, size: CGFloat, textColor: UIColor) {
    self.text = text
    self.font = UIFont(name: font.rawValue, size: size) ?? UIFont.systemFont(ofSize: size)
    self.textColor = textColor
  }
  
}
