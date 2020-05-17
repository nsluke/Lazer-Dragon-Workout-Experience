//
//  OutrunStackView.swift
//  CodeDump
//
//  Created by Someone on Stack Overflow.
//  Copyright © 2020 Observatory. All rights reserved.
//

import UIKit

class OutrunStackView : UIStackView {
  
  private var color: UIColor?
  override var backgroundColor: UIColor? {
      get { return color }
      set {
          color = newValue
          self.setNeedsLayout()
      }
  }

  private lazy var backgroundLayer: CAShapeLayer = {
      let layer = CAShapeLayer()
      self.layer.insertSublayer(layer, at: 0)
      return layer
  }()
  
  override func layoutSubviews() {
      super.layoutSubviews()
      backgroundLayer.path = UIBezierPath(rect: self.bounds).cgPath
      backgroundLayer.fillColor = self.backgroundColor?.cgColor
  }
  
  func addBackground(color: UIColor) {
       let subview = UIView(frame: bounds)
       subview.backgroundColor = color
       subview.autoresizingMask = [.flexibleWidth, .flexibleHeight]
       insertSubview(subview, at: 0)
   }

  
}
