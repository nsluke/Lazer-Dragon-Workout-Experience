//
//  PreviewWorkoutViewModel.swift
//  CodeDump
//
//  Created by Luke Solomon on 9/2/20.
//  Copyright © 2020 Observatory. All rights reserved.
//

import UIKit


protocol PreviewWorkoutViewModelDelegate: AnyObject {
  func refreshTable()
  func doneButtonTapped()
}

class PreviewWorkoutViewModel:NSObject {

  // Injected from WorkoutViewController when initialized
  var workout:WorkoutModel? = nil
  unowned var delegate : PreviewWorkoutViewModelDelegate? = nil // unowned, because the reference needs to be weak but it's always going to be there
  
}

extension PreviewWorkoutViewModel: UITableViewDataSource {
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    // sections:
    // 0 - Warmup
    // 1 - Cooldown
    // 2 - Number of Sets, cooldown between sets
    // 3 - Intervals
    
    if section == 0 {
      return 1
    } else if section == 1 {
      return 1
    } else if section == 2 {
      return 1
    } else if section == 3 {
      return (workout?.exercises.count ?? 0)
    } else {
      return 0
    }
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 4
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "PreviewCell", for: indexPath) as! PreviewWorkoutCell
        
    if indexPath.section == 0 {
      
      let viewModel = OutrunTableViewCellModel(
        titleText: "Warmup: \(String.timeToFormattedString(time: workout!.warmupLength))",
        font: .Pixel,
        fontSize: 24,
        textColor: .OutrunLaserGreen)
      
      cell.configure(viewModel: viewModel)
      
    } else if indexPath.section == 1 {
      
      let viewModel = OutrunTableViewCellModel(
        titleText: "Cooldown: \(String.timeToFormattedString(time: workout!.cooldownLength))",
        font: .Pixel,
        fontSize: 24,
        textColor: .OutrunLaserGreen)
      
      cell.configure(viewModel: viewModel)
      
    } else if indexPath.section == 2 {

      let viewModel = OutrunTableViewCellModel(
        titleText: "\(workout!.numberOfSets) sets, \(String.timeToFormattedString(time: workout!.restBetweenSetLength)) rest between each",
        font: .Pixel,
        fontSize: 24,
        textColor: .OutrunLaserGreen)
      
      cell.configure(viewModel: viewModel)
      
    } else if indexPath.section == 3 {
      
      var viewModel = OutrunTableViewCellModel(
        titleText: "",
        font: .Pixel,
        fontSize: 24,
        textColor: .OutrunPaleYellow
      )
      
      if indexPath.row == 0 {
        
        viewModel.titleText = "\(workout?.numberOfIntervals ?? 0) intervals, \(String.timeToFormattedString(time: workout!.intervalLength)) seconds each"
        viewModel.textColor = .OutrunLaserGreen
        
      } else if indexPath.row == 1 {
        
        viewModel.titleText = "\(workout!.restLength) seconds rest between each"
        viewModel.textColor = .OutrunLaserGreen
        
      } else {
        
        var text = "\(workout?.exercises[indexPath.row - 2].name ?? "")"
        if workout?.exercises[indexPath.row - 2].reps ?? 0 > 0 {
          text.append("x \(workout!.exercises[indexPath.row - 2].reps)")
        }
        viewModel.titleText = text
      }
      cell.configure(viewModel: viewModel)
    }
    
    return cell
  }
  
  @objc func doneButtonTapped() {
    delegate?.doneButtonTapped()
  }
  
}

extension PreviewWorkoutViewModel: UITableViewDelegate {
  
  func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    if section == 3 { // last section
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

      button.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
      return view
    } else {
      
      let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 20.0))
      view.backgroundColor = UIColor.OutrunDarkerGray
      
      return view
    }
  }
  
  func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    if section == 3 { // last section
      return 80.0
    } else {
      return 20.0
    }
  }
  
}
