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
  
  
  init(tableView:UITableView) {
    self.tableView = tableView
  }
}

extension RoutineDesignerTableViewHandler : UITableViewDataSource {
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 5
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "RoutineCell", for: indexPath) as! RoutineDesignerTableViewCell
    
    cell.setupViews()
    
    if indexPath.section == 0 {
      
      cell.label.customize(
        text: "Name Your Workout:",
        font: .Pixel,
        size: 20,
        textColor: UIColor.OutrunYellow
      )
      cell.textField.isHidden = false
      
    } else if indexPath.section == 1 {
      cell.label.customize(
        text: "Warmup Length",
        font: .Pixel,
        size: 20,
        textColor: UIColor.OutrunYellow
      )
      cell.textField.isHidden = true
      
    } else if indexPath.section == 2 {
      cell.label.customize(
        text: "Intervals",
        font: .Pixel,
        size: 20,
        textColor: UIColor.OutrunYellow
      )
      cell.textField.isHidden = true
      
    } else if indexPath.section == 3 {
      cell.label.customize(
        text: "Cool Down",
        font: .Pixel,
        size: 20,
        textColor: UIColor.OutrunYellow
      )
      cell.textField.isHidden = true

    }
    
    
    return cell
  }
}


extension RoutineDesignerTableViewHandler : UITableViewDelegate {

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
    if indexPath.section == 2 {
      
    }
    
    
  }
  
  
}
