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
  func sequeToExercisesDesigner()
}

class RoutineDesignerTableViewCell : OutrunTableViewCell {
  
  override func setupViews() {
    super.setupViews()
    
    self.containerView.removeArrangedSubview(self.icon)
  }
  
}


class RoutineDesignerNameCell : OutrunTableViewCell {
  
  var textField = OutrunTextField()
    
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    
    self.contentView.addSubview(containerView)
    containerView.translatesAutoresizingMaskIntoConstraints = false
    containerView.axis = .horizontal
    containerView.distribution = .fill
    containerView.alignment = .fill
    containerView.spacing = 8.0
    
    self.containerView.addArrangedSubview(label)
    self.containerView.addArrangedSubview(textField)
    
    containerView.anchor(
      top: self.contentView.topAnchor,
      left: self.contentView.leftAnchor,
      bottom: self.contentView.bottomAnchor,
      right: self.contentView.rightAnchor,
      paddingTop: 8,
      paddingLeft: 8,
      paddingBottom: 8,
      paddingRight: 8,
      width: 0,
      height: 0,
      enableInsets: true)
    
    textField.anchor(
      top: nil,
      left: label.rightAnchor,
      bottom: nil,
      right: nil,
      paddingTop: 0,
      paddingLeft: 8,
      paddingBottom: 0,
      paddingRight: 0,
      width: 0,
      height: 0,
      enableInsets: true)
    
    label.setContentHuggingPriority(.defaultLow + 1, for: .horizontal)
    label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    
    textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
    textField.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)
    
    textField.textAlignment = .left
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
