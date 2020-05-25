//
//  IntervalVisualizationCell.swift
//  CodeDump
//
//  Created by Luke Solomon on 5/25/20.
//  Copyright © 2020 Observatory. All rights reserved.
//

import UIKit



protocol IntervalVisualizationCellDelegate {
  func returnValue()
}

// MARK: IntervalVisualizationCell
class IntervalVisualizationCell : UITableViewCell {
  
  var visualizationView = IntervalVisualizationView()
  
  func configure(viewModel: IntervalVisualizationViewModel) {
    self.contentView.addSubview(visualizationView)
    
    visualizationView.configure(viewModel: viewModel)
    
    visualizationView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 8, paddingLeft: 8, paddingBottom: 8, paddingRight: 8, width: 0, height: 0, enableInsets: true)
    
  }
  
}

struct IntervalVisualizationViewModel {
  var warmupLength   : Int
  var intervalCount  : Int
  var intervalLength : Int
  var restLength     : Int
  var cooldownLength : Int
}

// takes a couple of variables and builds a simple visualization of the workout
class IntervalVisualizationView : UIView {
  
  var containerView = OutrunStackView()
  var viewModel:IntervalVisualizationViewModel?
  
  func configure(viewModel: IntervalVisualizationViewModel) {
    self.viewModel = viewModel
    self.addSubview(containerView)
//    self.backgroundColor = UIColor.OutrunBlack
    containerView.distribution = .fillEqually
    containerView.alignment = .fill
    containerView.axis = .horizontal
    containerView.translatesAutoresizingMaskIntoConstraints = false
//    containerView.addBackground(color: UIColor.OutrunBlack)
    
    containerView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0, enableInsets: false)
    
    // To create these bars correctly:
    // 1.) Find the length of the workout = L
    // 2.) Find the width of the containerView = W
    // 3.) Find the value of the piece of the workout = P
    // 3.) (W / L) * P = Proportional width of the individual bar
    
    let workoutLength = viewModel.warmupLength + (viewModel.intervalCount * (viewModel.intervalLength + viewModel.restLength)) + viewModel.cooldownLength
    
    let width = UIScreen.main.bounds.width - 30
    
    let warmupProportionalWidth = (width / CGFloat(workoutLength)) * CGFloat(viewModel.warmupLength)
    let intervalProportionalWidth = (width / CGFloat(workoutLength)) * CGFloat(viewModel.intervalLength)
    let restProportionalWidth = (width / CGFloat(workoutLength)) * CGFloat(viewModel.restLength)
    let cooldownProportionalWidth = (width / CGFloat(workoutLength)) * CGFloat(viewModel.cooldownLength)
     
    if viewModel.warmupLength > 0 {
      let view = UIView(frame: CGRect(x: 0, y: 0, width: warmupProportionalWidth, height:containerView.frame.height))
      view.backgroundColor = UIColor.OutrunOrange
      containerView.addArrangedSubview(view)
    }
    
    for _ in 0..<viewModel.intervalCount {
      let intervalView = UIView(frame: CGRect(x: 0, y: 0, width: intervalProportionalWidth, height: 120))
      intervalView.backgroundColor = UIColor.OutrunRed
      containerView.addArrangedSubview(intervalView)
      
      let restView = UIView(frame: CGRect(x: 0, y: 0, width: restProportionalWidth, height: 120))
      restView.backgroundColor = UIColor.OutrunLaserBlue
      containerView.addArrangedSubview(restView)
    }
    
    if viewModel.cooldownLength > 0 {
      let cooldownView = UIView(frame: CGRect(x: 0, y: 0, width: cooldownProportionalWidth, height: 120))
      cooldownView.backgroundColor = UIColor.OutrunPink
      containerView.addArrangedSubview(cooldownView)
    }

//    containerView.setNeedsLayout()
  }
  
}
