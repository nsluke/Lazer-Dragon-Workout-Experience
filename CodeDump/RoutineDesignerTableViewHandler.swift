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
    
    
    
    
    return cell
  }
}


extension RoutineDesignerTableViewHandler : UITableViewDelegate {

}
