//
//  UIView+Extension.swift
//  Sample_TableView
//
//  Created by Esat Kemal Ekren on 5.04.2018.
//  Copyright © 2018 Esat Kemal Ekren. All rights reserved.
//
//  Note: This was a cool extension I found on github.
//  https://github.com/kemalekren/Sample-Custom-TableView-Project-/blob/master/Sample_TableView/Extension.swift
// Reference Video: https://youtu.be/iqpAP7s3b-8



import UIKit

extension UIView {
  
  func pinToSuper() {
    
    anchor(
      top: topAnchor,
      left: leftAnchor,
      bottom: bottomAnchor,
      right: rightAnchor,
      paddingTop: 0,
      paddingLeft: 0,
      paddingBottom: 0,
      paddingRight: 0,
      width: 0,
      height: 0,
      enableInsets: false
    )
    
  }
  
  
  func anchor (
    top: NSLayoutYAxisAnchor?,
    left: NSLayoutXAxisAnchor?,
    bottom: NSLayoutYAxisAnchor?,
    right: NSLayoutXAxisAnchor?,
    paddingTop: CGFloat,
    paddingLeft: CGFloat,
    paddingBottom: CGFloat,
    paddingRight: CGFloat,
    width: CGFloat,
    height: CGFloat,
    enableInsets: Bool
  ) {
    
    var topInset = CGFloat(0)
    var bottomInset = CGFloat(0)
    var leftInset = CGFloat(0)
    var rightInset = CGFloat(0)
    
    if #available(iOS 11, *), enableInsets {
      let insets = self.safeAreaInsets
      topInset = insets.top
      bottomInset = insets.bottom
      leftInset = insets.left
      rightInset = insets.right
      
      print("TopInset: \(topInset)")
      print("BottomInset: \(bottomInset)")
    }
    
    translatesAutoresizingMaskIntoConstraints = false
    
    if let top = top {
      self.topAnchor.constraint(equalTo: top, constant: paddingTop+topInset).isActive = true
    }
    if let left = left {
      self.leftAnchor.constraint(equalTo: left, constant: paddingLeft+leftInset).isActive = true
    }
    if let right = right {
      rightAnchor.constraint(equalTo: right, constant: -paddingRight-rightInset).isActive = true
    }
    if let bottom = bottom {
      bottomAnchor.constraint(equalTo: bottom, constant: -paddingBottom-bottomInset).isActive = true
    }
    if height != 0 {
      heightAnchor.constraint(equalToConstant: height).isActive = true
    }
    if width != 0 {
      widthAnchor.constraint(equalToConstant: width).isActive = true
    }
    
  }
  
  func fillSuperview(padding: UIEdgeInsets = .zero) {
    translatesAutoresizingMaskIntoConstraints = false
    if let superviewTopAnchor = superview?.topAnchor {
      topAnchor.constraint(equalTo: superviewTopAnchor, constant: padding.top).isActive = true
    }
    
    if let superviewBottomAnchor = superview?.bottomAnchor {
      bottomAnchor.constraint(equalTo: superviewBottomAnchor, constant: -padding.bottom).isActive = true
    }
    
    if let superviewLeadingAnchor = superview?.leadingAnchor {
      leadingAnchor.constraint(equalTo: superviewLeadingAnchor, constant: padding.left).isActive = true
    }
    
    if let superviewTrailingAnchor = superview?.trailingAnchor {
      trailingAnchor.constraint(equalTo: superviewTrailingAnchor, constant: -padding.right).isActive = true
    }
  }
  
  func centerInSuperview(size: CGSize = .zero) {
    translatesAutoresizingMaskIntoConstraints = false
    if let superviewCenterXAnchor = superview?.centerXAnchor {
      centerXAnchor.constraint(equalTo: superviewCenterXAnchor).isActive = true
    }
    
    if let superviewCenterYAnchor = superview?.centerYAnchor {
      centerYAnchor.constraint(equalTo: superviewCenterYAnchor).isActive = true
    }
    
    if size.width != 0 {
      widthAnchor.constraint(equalToConstant: size.width).isActive = true
    }
    
    if size.height != 0 {
      heightAnchor.constraint(equalToConstant: size.height).isActive = true
    }
  }
  
  func centerXInSuperview() {
    translatesAutoresizingMaskIntoConstraints = false
    if let superViewCenterXAnchor = superview?.centerXAnchor {
      centerXAnchor.constraint(equalTo: superViewCenterXAnchor).isActive = true
    }
  }
  
  func centerYInSuperview() {
    translatesAutoresizingMaskIntoConstraints = false
    if let centerY = superview?.centerYAnchor {
      centerYAnchor.constraint(equalTo: centerY).isActive = true
    }
  }
  
  func constrainWidth(constant: CGFloat) {
    translatesAutoresizingMaskIntoConstraints = false
    widthAnchor.constraint(equalToConstant: constant).isActive = true
  }
  
  func constrainHeight(constant: CGFloat) {
    translatesAutoresizingMaskIntoConstraints = false
    heightAnchor.constraint(equalToConstant: constant).isActive = true
  }
}

struct AnchoredConstraints {
  var top, leading, bottom, trailing, width, height: NSLayoutConstraint?
}
