//
//  RoutineDesignerViewController.swift
//  CodeDump
//
//  Created by Luke Solomon on 5/11/20.
//  Copyright © 2020 Observatory. All rights reserved.
//

import UIKit

let doneNotification = "RoutineDoneDesign"


class RoutineDesignerViewController: OutrunViewController {
  
  var workout:WorkoutModel?
  var tableView = UITableView()
  var tableViewHandler:RoutineDesignerTableViewHandler!

  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if let workout = workout  {
      self.workout = workout
    } else {
      self.workout = WorkoutModel(name: "", type: .Custom, length: 0, warmupLength: 0, intervalLength: 0, restLength: 0, numberOfIntervals: 0, numberOfSets: 0, restBetweenSetLength: 0, cooldownLength: 0)
    }
    setupViews()
    NotificationCenter.default.addObserver(self, selector: #selector(doneButtonHandling), name: NSNotification.Name(rawValue: doneNotification), object: nil)
  }
  
  func setupViews() {
    self.title = "Design your Workout"
    navigationItem.largeTitleDisplayMode = .never
    navigationItem.backBarButtonItem?.tintColor = UIColor.OutrunLaserBlue
    navigationController?.navigationBar.backgroundColor = UIColor.OutrunDarkerGray
    navigationController?.navigationBar.barTintColor = UIColor.OutrunDarkerGray
    
    view.backgroundColor = UIColor.OutrunDarkerGray
    tableView.backgroundColor = UIColor.OutrunDarkerGray
    
    // TableView
    let handler = RoutineDesignerTableViewHandler(tableView: tableView, workout: self.workout!, routineCellDelegate: self, textFieldDelegate: self)
    tableViewHandler = handler
    tableView.delegate = tableViewHandler
    tableView.dataSource = tableViewHandler
    tableView.register(RoutineDesignerNameCell.self, forCellReuseIdentifier: "RoutineNameCell")
    tableView.register(RoutineDesignerTableViewCell.self, forCellReuseIdentifier: "RoutineCell")
    tableView.register(IntervalVisualizationCell.self, forCellReuseIdentifier: "VisualizationCell")
    tableView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tableView)
    tableView.isUserInteractionEnabled = true
    tableView.allowsSelection = true
    
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      tableView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor)
    ])
  }

  
  @objc func tapGestureHandler(sender: UITapGestureRecognizer!) {
    self.resignFirstResponder()
  }
  
  @objc func doneButtonHandling(notification: NSNotification) {
    
    if self.tableViewHandler.workout.name == "" {
      print("workout needs a name")
    }
    
    DataHandler.shared.saveWorkouts(workoutModels: [self.tableViewHandler.workout], completion: {
      print("Workout saved")
      self.navigationController?.popViewController(animated: true)
    })
  }
  
}

extension RoutineDesignerViewController: RoutineDesignerCellDelegate {
  func returnValue() {
    
  }
  
  func segueToIntervalDesigner() {
    let intervalVC = IntervalDesignerViewController()
    intervalVC.workout = self.tableViewHandler.workout
    intervalVC.delegate = self
    navigationController?.pushViewController(intervalVC, animated: true)
  }
  
  func sequeToExercisesDesigner() {
    let exerciseVC = ExercisesDesignerViewController()
    exerciseVC.workout = self.tableViewHandler.workout
    exerciseVC.delegate = self
    navigationController?.pushViewController(exerciseVC, animated: true)
  }
}

extension RoutineDesignerViewController: IntervalDesignerDelegate {
  func finishedEditing(workout: WorkoutModel) {
    self.tableViewHandler.workout = workout
  }
}

extension RoutineDesignerViewController: ExercisesDesignerCellDelegate {
  func returnExercise(workoutModel: WorkoutModel) {
    self.tableViewHandler.workout = workoutModel
  }
}

extension RoutineDesignerViewController: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    guard let textFieldText = textField.text else {
      return true
    }
    
    self.tableViewHandler.workout.name = textFieldText
    textField.resignFirstResponder()

    return true
  }
  
  func textFieldDidBeginEditing(_ textField: UITextField) {
    guard let textFieldText = textField.text else {
      return
    }
    
    self.tableViewHandler.workout.name = textFieldText
  }
  
  func textFieldDidEndEditing(_ textField: UITextField) {
    guard let textFieldText = textField.text else {
      return
    }
    
    self.tableViewHandler.workout.name = textFieldText
  }
  
  func textFieldShouldClear(_ textField: UITextField) -> Bool {
    guard let textFieldText = textField.text else {
      return true
    }
    
    self.tableViewHandler.workout.name = ""

    return true
  }
  
  
}
