//
//  RoutineDesignerTableViewCell.swift
//  CodeDump
//
//  Created by Luke Solomon on 5/13/20.
//  Copyright © 2020 Observatory. All rights reserved.
//

import UIKit



class RoutineDesignerTableViewCell : UITableViewCell {
  var icon = UIImage()
  var label = UILabel()
  var descriptorLabel = UILabel()
}

class IntervalVisualizationCell : UITableViewCell {
  
  var visualizationView: IntervalVisualizationView
  
  
  
  
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
  
  var containerView = UIStackView()
  var viewModel:IntervalVisualizationViewModel?
  
  func configure(viewModel: IntervalVisualizationViewModel) {
    self.viewModel = viewModel
    
    if viewModel.warmupLength > 0 {
      let view = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: viewModel.warmupLength))
      view.backgroundColor = UIColor.OutrunOrange
      containerView.addArrangedSubview(view)
    }
    
    
    for _ in 0..<viewModel.intervalCount {
      let intervalView = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: viewModel.intervalLength))
      intervalView.backgroundColor = UIColor.OutrunRed
      containerView.addArrangedSubview(intervalView)
      
      let restView = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: viewModel.restLength))
      restView.backgroundColor = UIColor.OutrunLaserBlue
      containerView.addArrangedSubview(restView)
    }
    
    if viewModel.cooldownLength > 0 {
      let cooldownView = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: viewModel.cooldownLength))
      view.backgroundColor = UIColor.OutrunOffPurple
      containerView.addArrangedSubview(view)
    }

    
  }
  
}
