//
//  RoutineDesignerTableViewCell.swift
//  CodeDump
//
//  Created by Luke Solomon on 5/13/20.
//  Copyright © 2020 Observatory. All rights reserved.
//

import UIKit

protocol RoutineDesignerCellDelegate {
  func returnValue()
  func segueToIntervalDesigner()
}

class RoutineDesignerTableViewCell : UITableViewCell {
  var icon = UIImageView()
  var label = OutrunLabel()
  var descriptorLabel = OutrunLabel()
  
  var containerView = OutrunStackView()
  
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    
    
    self.contentView.addSubview(icon)
    self.contentView.addSubview(label)
    self.contentView.addSubview(descriptorLabel)
    
    icon.anchor(
      top: topAnchor,
      left: leftAnchor,
      bottom: bottomAnchor,
      right: label.leftAnchor,
      paddingTop: 0,
      paddingLeft: 0,
      paddingBottom: 0,
      paddingRight: 0,
      width: 30,
      height: 0,
      enableInsets: false)
    
    label.anchor(
      top: topAnchor,
      left: icon.rightAnchor,
      bottom: bottomAnchor,
      right: descriptorLabel.leftAnchor,
      paddingTop: 8,
      paddingLeft: 8,
      paddingBottom: 8,
      paddingRight: 8,
      width: 0,
      height: 0,
      enableInsets: true)

    descriptorLabel.anchor(
      top: topAnchor,
      left: label.rightAnchor,
      bottom: bottomAnchor,
      right: rightAnchor,
      paddingTop: 8,
      paddingLeft: 8,
      paddingBottom: 8,
      paddingRight: 8,
      width: 200,
      height: 0,
      enableInsets: true)
    descriptorLabel.textAlignment = .right
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func setupViews() {
    self.contentView.backgroundColor = UIColor.OutrunDarkerGray
  }
  
}



class RoutineDesignerNameCell : UITableViewCell {

  var icon = UIImageView()
  var label = OutrunLabel()
  var textField = OutrunTextField()
  
  var containerView = OutrunStackView()
  
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    
    
    self.contentView.addSubview(icon)
    self.contentView.addSubview(label)
    self.contentView.addSubview(textField)
    
    icon.anchor(
      top: topAnchor,
      left: leftAnchor,
      bottom: bottomAnchor,
      right: label.leftAnchor,
      paddingTop: 0,
      paddingLeft: 0,
      paddingBottom: 0,
      paddingRight: 0,
      width: 30,
      height: 0,
      enableInsets: false)
    
    label.anchor(
      top: topAnchor,
      left: icon.rightAnchor,
      bottom: bottomAnchor,
      right: textField.leftAnchor,
      paddingTop: 8,
      paddingLeft: 8,
      paddingBottom: 8,
      paddingRight: 8,
      width: 0,
      height: 0,
      enableInsets: true)
    
    textField.anchor(
      top: topAnchor,
      left: label.rightAnchor,
      bottom: bottomAnchor,
      right: rightAnchor,
      paddingTop: 8,
      paddingLeft: 8,
      paddingBottom: 8,
      paddingRight: 8,
      width: 200,
      height: 0,
      enableInsets: true)
    textField.textAlignment = .right
      
    }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func setupViews() {
    self.contentView.backgroundColor = UIColor.OutrunDarkerGray
  }
  
}
