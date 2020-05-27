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
  
  var containerView = OutrunStackView()
  
  var tableViewHandler:RoutineDesignerTableViewHandler!
  var tableView = UITableView()
  

  override func viewDidLoad() {
    super.viewDidLoad()
    
    if let workout = workout  {
      self.workout = workout
    } else {
      self.workout = WorkoutModel("", .Custom, 0, 0, 0, 0, 0, 0)
    }
    
    
    title = "Design your Workout"
    navigationItem.largeTitleDisplayMode = .never
    navigationItem.backBarButtonItem?.tintColor = UIColor.OutrunLaserBlue
//    navigationController
    setupViews()
  }
  
  
  func setupViews() {
    view.addSubview(containerView)
    view.backgroundColor = UIColor.OutrunDarkerGray
    tableView.backgroundColor = UIColor.OutrunDarkerGray
    
    containerView.translatesAutoresizingMaskIntoConstraints = false
    containerView.axis = .vertical
    containerView.distribution = .fillEqually
    containerView.alignment = .center
    
    // TableView
    tableViewHandler = RoutineDesignerTableViewHandler.init(tableView: tableView, workout: self.workout!)
    tableViewHandler.routineDesignerDelegate = self
//    tableViewHandler.textFieldDelegate = self
    tableView.delegate = tableViewHandler
    tableView.dataSource = tableViewHandler
    tableView.register(RoutineDesignerNameCell.self, forCellReuseIdentifier: "RoutineNameCell")
    tableView.register(RoutineDesignerTableViewCell.self, forCellReuseIdentifier: "RoutineCell")
    tableView.register(IntervalVisualizationCell.self, forCellReuseIdentifier: "VisualizationCell")


    
    containerView.addArrangedSubview(tableView)

    NSLayoutConstraint.activate([
      containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
      containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      containerView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
      containerView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
      
      tableView.topAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.topAnchor),
      tableView.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor),
      tableView.leftAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.rightAnchor)
    ])
  }
  
}

extension RoutineDesignerViewController: RoutineDesignerCellDelegate {
  func returnValue() {
    
  }
  
  
  func segueToIntervalDesigner() {
    let intervalVC = IntervalDesignerViewController()
    
    navigationController?.pushViewController(intervalVC, animated: true)
  }
  
}


