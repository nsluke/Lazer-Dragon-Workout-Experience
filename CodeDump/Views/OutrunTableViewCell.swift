//
//  OutrunTableViewCell.swift
//  CodeDump
//
//  Created by Luke Solomon on 9/3/20.
//  Copyright © 2020 Observatory. All rights reserved.
//

import UIKit

struct OutrunTableViewCellModel {
  var titleText: String
  var font: OutrunFonts
  var fontSize: CGFloat
  var textColor: UIColor
}

class OutrunTableViewCell: UITableViewCell {
  var icon = UIImageView()
  var label = OutrunLabel()
  var descriptorLabel = OutrunLabel()
  
  var containerView = OutrunStackView()
  
  var viewModel:OutrunTableViewCellModel? = nil
  
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    
    self.contentView.backgroundColor = UIColor.OutrunDarkerGray
    self.contentView.addSubview(containerView)
    containerView.translatesAutoresizingMaskIntoConstraints = false
    containerView.axis = .horizontal
    containerView.distribution = .fillProportionally
    containerView.alignment = .center
    
    self.containerView.addArrangedSubview(icon)
    self.containerView.addArrangedSubview(label)
    self.containerView.addArrangedSubview(descriptorLabel)
    
    containerView.anchor(
      top: topAnchor,
      left: leftAnchor,
      bottom: bottomAnchor,
      right: rightAnchor,
      paddingTop: 0,
      paddingLeft: 8,
      paddingBottom: 0,
      paddingRight: 8,
      width: 0,
      height: 0,
      enableInsets: true)
    
    label.setContentHuggingPriority(.defaultLow + 1, for: .horizontal)
    label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    
    descriptorLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
    descriptorLabel.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)
    
    descriptorLabel.textAlignment = .right
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func configure(viewModel:OutrunTableViewCellModel) {
    self.label.customize(
      text: viewModel.titleText,
      font: viewModel.font,
      size: viewModel.fontSize,
      textColor: viewModel.textColor
    )
  }
  
  func setupViews() {
    self.contentView.backgroundColor = UIColor.OutrunDarkerGray
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
  }
  
}
