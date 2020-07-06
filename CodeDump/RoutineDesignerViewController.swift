//
//  RoutineDesignerViewController.swift
//  CodeDump
//
//  Created by Luke Solomon on 5/11/20.
//  Copyright © 2020 Observatory. All rights reserved.
//

import UIKit



class RoutineDesignerViewController: OutrunViewController {
  
  var workout:WorkoutModel?
  
  var containerView = OutrunStackView()
  
  var tableViewHandler:RoutineDesignerTableViewHandler!
  var tableView = UITableView()
  
  var doneButton = UIButton()
  

  override func viewDidLoad() {
    super.viewDidLoad()
    
    if let workout = workout  {
      self.workout = workout
    } else {
      self.workout = WorkoutModel(name: "", type: .Custom, length: 0, warmupLength: 0, intervalLength: 0, restLength: 0, numberOfIntervals: 0, numberOfSets: 0, restBetweenSetLength: 0, cooldownLength: 0)
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
    
    doneButton.titleLabel?.text = "Done"
    containerView.addArrangedSubview(doneButton)
    doneButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
    
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
  
  @objc func doneButtonTapped(sender: UIButton!) {
    // TODO: add validation for workout
//    CoreDataHandler().saveWorkout(workoutModel: self.workout!) {
//      self.navigationController?.popViewController(animated: true)
//    }
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


