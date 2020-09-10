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
  
  var workout:WorkoutModel
  var exercises = [String]()
  
  var intervalCellDelegate:IntervalVisualizationCellDelegate?
  var routineDesignerCellDelegate:RoutineDesignerCellDelegate?
  var textFieldDelegate:UITextFieldDelegate?

  
  init(tableView:UITableView, workout:WorkoutModel, routineCellDelegate: RoutineDesignerCellDelegate, textFieldDelegate:UITextFieldDelegate) {
    self.tableView = tableView
    
    self.workout = workout
    
    self.routineDesignerCellDelegate = routineCellDelegate
    self.textFieldDelegate = textFieldDelegate
    super.init()
    
    self.intervalCellDelegate = self
  }
  
  @objc func broadcastDoneTapped() {
    
    NotificationCenter.default.post(name: NSNotification.Name(rawValue: doneNotification), object: nil, userInfo: ["workout":self.workout])
  }
  
}

extension RoutineDesignerTableViewHandler : UITableViewDataSource {
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if indexPath.section == 4 {
      return 80
    } else {
      return 50
    }
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 7 + self.workout.exercises.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    // ============================ Name your workout cell ============================ //
    if indexPath.row == 0 {
      let cell = tableView.dequeueReusableCell(withIdentifier: "RoutineNameCell", for: indexPath)  as! RoutineDesignerNameCell
      
      cell.label.customize(
        text: "Name Your Workout:",
        font: .Pixel,
        size: 24,
        textColor: UIColor.OutrunPaleYellow
      )
      cell.textField.delegate = textFieldDelegate
      cell.textField.isHidden = false
      cell.textField.customizeWithStandardValues(placeholder: "_")
      cell.setupViews()
      return cell
      
    // ============================ Warmup ============================ //
    } else if indexPath.row == 1 {
      let cell = tableView.dequeueReusableCell(withIdentifier: "RoutineCell", for: indexPath)  as! RoutineDesignerTableViewCell

      cell.label.customize(
        text: "Warmup Length:",
        font: .Pixel,
        size: 24,
        textColor: UIColor.OutrunPaleYellow
      )
      
      cell.descriptorLabel.customize(
        text: String(self.workout.warmupLength),
        font: .Pixel,
        size: 24,
        textColor: UIColor.OutrunPaleYellow
      )
      
      cell.setupViews()
      return cell
      
      // ============================ CoolDown ============================ //
      } else if indexPath.row == 2 {
      
        let cell = tableView.dequeueReusableCell(withIdentifier: "RoutineCell", for: indexPath)  as! RoutineDesignerTableViewCell

        cell.label.customize(
          text: "Cool Down:",
          font: .Pixel,
          size: 24,
          textColor: UIColor.OutrunPaleYellow
        )
        
        cell.descriptorLabel.customize(
          text: String(self.workout.cooldownLength),
          font: .Pixel,
          size: 24,
          textColor: UIColor.OutrunPaleYellow
        )
        
        cell.setupViews()
        return cell

    // ============================ Intervals ============================ //
    } else if indexPath.row == 3 {
      let cell = tableView.dequeueReusableCell(withIdentifier: "RoutineCell", for: indexPath)  as! RoutineDesignerTableViewCell
      
      cell.label.customize(
        text: "Intervals:",
        font: .Pixel,
        size: 24,
        textColor: UIColor.OutrunPaleYellow
      )
      
      cell.descriptorLabel.customize(
        text: ">",
        font: .Pixel,
        size: 24,
        textColor: UIColor.OutrunLaserBlue
      )
      
      cell.setupViews()
      return cell

    // ============================ Interval Visualization Cell ============================ //
    } else if indexPath.row == 4 {
      let intervalVisualizationCell = tableView.dequeueReusableCell(withIdentifier: "VisualizationCell", for: indexPath)  as! IntervalVisualizationCell

      let viewModel = IntervalVisualizationViewModel(warmupLength: 500, intervalCount: 10, intervalLength: 60, restLength: 30, cooldownLength: 500)
      
      intervalVisualizationCell.configure(viewModel: viewModel)
      
      return intervalVisualizationCell
      
    // ============================ Exercises ============================ //
    } else if indexPath.row == 5 {
      let cell = tableView.dequeueReusableCell(withIdentifier: "RoutineCell", for: indexPath)  as! RoutineDesignerTableViewCell
      cell.label.text = ""
      cell.descriptorLabel.text = ""
      
      
      cell.label.customize(
        text: "Exercises:",
        font: .Pixel,
        size: 24,
        textColor: UIColor.OutrunPaleYellow
      )
      
      cell.descriptorLabel.customize(
        text: "+",
        font: .Pixel,
        size: 30,
        textColor: UIColor.OutrunLaserBlue
      )
      
      cell.setupViews()
      return cell

    } else if indexPath.row > 5 {
      let cell = tableView.dequeueReusableCell(withIdentifier: "RoutineCell", for: indexPath)  as! RoutineDesignerTableViewCell

      cell.label.text = ""
      cell.descriptorLabel.text = ""
      
      if self.exercises.count < 0 {
        cell.label.customize(
          text: self.exercises[indexPath.row + 6],
          font: .Pixel,
          size: 24,
          textColor: UIColor.OutrunPaleYellow
        )
      }
      
      cell.setupViews()
      return cell
    } else {
      let cell = tableView.dequeueReusableCell(withIdentifier: "RoutineCell", for: indexPath)  as! RoutineDesignerTableViewCell
      
      cell.setupViews()
      
      return cell
    }
  }
  
  func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 80))
    view.backgroundColor = UIColor.OutrunDarkerGray

    let button = OutrunButton(frame: CGRect(x: (tableView.frame.width/2) - 75, y: 0, width: 150, height: 80))
    view.addSubview(button)

    button.customize(
      text: "Done",
      font: .Future,
      size: 40,
      textColor: .OutrunLaserBlue
    )

    button.addTarget(self, action: #selector(broadcastDoneTapped), for: .touchUpInside)
    return view
  }
  
  func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    return 80.0
  }
}

extension RoutineDesignerTableViewHandler : UITableViewDelegate {
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
    if indexPath.row == 3 {
      routineDesignerCellDelegate!.segueToIntervalDesigner()
    } else if indexPath.row == 5 {
      routineDesignerCellDelegate!.sequeToExercisesDesigner()
    } else {
      print("tapped")
    }
  }
  
}

extension RoutineDesignerTableViewHandler: IntervalVisualizationCellDelegate {
  func returnValue() {
    
  }
}
