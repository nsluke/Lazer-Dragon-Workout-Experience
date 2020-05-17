//
//  RoutineDesignerViewController.swift
//  CodeDump
//
//  Created by Luke Solomon on 5/11/20.
//  Copyright © 2020 Observatory. All rights reserved.
//

import UIKit


class RoutineDesignerViewController: UIViewController {
  
  var workout:WorkoutModel?
  
  var tableView = UITableView()
  var containerView = OutrunStackView()
  
  // Name
  var nameContainerView = OutrunStackView()
  var nameLabel = OutrunLabel()
  var nameTextField = UITextField()
  
  // Warmup
  var warmupContainerView = OutrunStackView()
  var warmupLengthTitleLabel = OutrunLabel()
  var warmupLengthDescriptorLabel = OutrunLabel()
  
  // Interval Count
  var intervalCountContainerVew = OutrunStackView()
  var intervalCountTitleLabel = OutrunLabel()
  var intervalCountDescriptorLabel = OutrunLabel()

  // Interval Length
  var intervalLengthContainerVew = OutrunStackView()
  var intervalLengthTitleLabel = OutrunLabel()
  var intervalLengthDescriptorLabel = OutrunLabel()
  
  // Cooldown Length
  var cooldownLengthContainerVew = OutrunStackView()
  var cooldownLengthTitleLabel = OutrunLabel()
  var cooldownLengthDescriptorLabel = OutrunLabel()
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    
  }
  
  
  func setupViews() {
    
    
    
  }
  
  
  
  
}
