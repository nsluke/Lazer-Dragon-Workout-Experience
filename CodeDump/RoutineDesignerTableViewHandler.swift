//
//  RoutineDesignerTableViewHandler.swift
//  CodeDump
//
//  Created by Luke Solomon on 5/13/20.
//  Copyright © 2020 Observatory. All rights reserved.
//

import UIKit


class RoutineDesignerTableViewHandler:NSObject {
  
  private var tableView:UITableView
  var intervalCellDelegate:IntervalVisualizationCellDelegate?

  init(tableView:UITableView) {
    self.tableView = tableView
  }
}

extension RoutineDesignerTableViewHandler : UITableViewDataSource {
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if indexPath.section == 3 {
      return 120
    } else {
      return 50
    }
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 5
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

    // ============================ Name your workout cell ============================ //
    if indexPath.section == 0 {
      let cell = tableView.dequeueReusableCell(withIdentifier: "RoutineCell", for: indexPath)  as! RoutineDesignerTableViewCell
      
      cell.label.customize(
        text: "Name Your Workout:",
        font: .Pixel,
        size: 24,
        textColor: UIColor.OutrunPaleYellow
      )
      cell.textField.isHidden = false
      cell.textField.customizeWithStandardValues(placeholder: "_")
      cell.setupViews()
      return cell

      // ============================ Warmup ============================ //
    } else if indexPath.section == 1 {
      let cell = tableView.dequeueReusableCell(withIdentifier: "RoutineCell", for: indexPath)  as! RoutineDesignerTableViewCell

      cell.label.customize(
        text: "Warmup Length:",
        font: .Pixel,
        size: 24,
        textColor: UIColor.OutrunPaleYellow
      )
      cell.textField.isHidden = true
      cell.setupViews()
      return cell

      // ============================ Intervals ============================ //
    } else if indexPath.section == 2 {
      let cell = tableView.dequeueReusableCell(withIdentifier: "RoutineCell", for: indexPath)  as! RoutineDesignerTableViewCell

      cell.label.customize(
        text: "Intervals:",
        font: .Pixel,
        size: 24,
        textColor: UIColor.OutrunPaleYellow
      )
      cell.textField.isHidden = true
      cell.setupViews()
      return cell

      
      // ============================ Interval Visualization Cell ============================ //
    } else if indexPath.section == 3 {
      let intervalVisualizationCell = tableView.dequeueReusableCell(withIdentifier: "VisualizationCell", for: indexPath)  as! IntervalVisualizationCell

      let viewModel = IntervalVisualizationViewModel(warmupLength: 500, intervalCount: 10, intervalLength: 60, restLength: 30, cooldownLength: 500)
      
      intervalVisualizationCell.configure(viewModel: viewModel)
      
      return intervalVisualizationCell
      
      // ============================ CoolDown ============================ //
    } else if indexPath.section == 4 {
      let cell = tableView.dequeueReusableCell(withIdentifier: "RoutineCell", for: indexPath)  as! RoutineDesignerTableViewCell

      cell.label.customize(
        text: "Cool Down:",
        font: .Pixel,
        size: 24,
        textColor: UIColor.OutrunPaleYellow
      )
      cell.textField.isHidden = true
      cell.setupViews()
      return cell

    } else {
      let cell = tableView.dequeueReusableCell(withIdentifier: "RoutineCell", for: indexPath)  as! RoutineDesignerTableViewCell
      
      return cell
    }
    
    
  }
}


extension RoutineDesignerTableViewHandler : UITableViewDelegate {

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
    if indexPath.section == 2 {
      
    }
    
    
  }
  
  
}
