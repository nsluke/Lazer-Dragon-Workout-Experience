//
//  SelectWorkoutViewController.swift
//  CodeDump
//
//  Created by Luke Solomon on 5/1/20.
//  Copyright © 2020 Observatory. All rights reserved.
//


import UIKit


class SelectWorkoutViewController: UIViewController {
  
  var tableView:UITableView = UITableView()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupViews()
  }
  
  func setupViews() {
    navigationController?.navigationBar.prefersLargeTitles = true
    title = "Select your Workout"
    
    view.backgroundColor = UIColor.OutrunDarkerGray
    navigationController?.navigationBar.titleTextAttributes = [
      .foregroundColor : UIColor.OutrunLaserBlue,
      .font : UIFont(name: "OutrunFuture", size: 18) ?? UIFont.systemFont(ofSize: 18)
    ]
    
    navigationController?.navigationBar.largeTitleTextAttributes = [
      .foregroundColor : UIColor.OutrunLaserBlue,
      .font : UIFont(name: "OutrunFuture", size: 30) ?? UIFont.systemFont(ofSize: 30)
    ]
    
    navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.addItemTapped))
    navigationItem.rightBarButtonItem?.tintColor = UIColor.OutrunLaserBlue
    
    tableView.dataSource = self
    tableView.delegate = self
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CellID")
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorStyle = .none
    tableView.backgroundColor = UIColor.OutrunDarkerGray
    
    view.addSubview(tableView)
    
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      tableView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor)
    ])
  }
  
  @objc func addItemTapped(sender:UIButton) {
    let routineDesignerVC = RoutineDesignerViewController()
    navigationController?.pushViewController(routineDesignerVC, animated: true)
  }
  
  
}
extension SelectWorkoutViewController:UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return Constants.WorkoutObject.count
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "CellID")
    
    cell?.textLabel?.text = Constants.WorkoutObject[indexPath.row].name
    cell?.textLabel?.textColor = UIColor.OutrunPaleYellow
    
    cell?.textLabel?.font = UIFont(name: "Pixel-01", size: 30) ?? UIFont.systemFont(ofSize: 20)
    
    cell?.backgroundColor = UIColor.OutrunDarkerGray
    cell?.selectionStyle = .default
    
    let selectedBackgroundView = UIView.init()
    selectedBackgroundView.backgroundColor = UIColor.OutrunDarkGray
    cell?.selectedBackgroundView = selectedBackgroundView
    
    return cell!
  }
}

extension SelectWorkoutViewController:UITableViewDelegate {
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    let workout = Constants.WorkoutObject[indexPath.row]
    let workoutVC = WorkoutViewController()
    let workoutDesignerVC = IntervalDesignerViewController()
    
    switch workout.type {
    case .HIIT:
      navigationController?.pushViewController(workoutVC, animated: true)
      workoutVC.workout = workout
    case .Run:
      navigationController?.pushViewController(workoutVC, animated: true)
      workoutVC.workout = workout
    case .Yoga:
      navigationController?.pushViewController(workoutVC, animated: true)
      workoutVC.workout = workout
    case .Strength:
      navigationController?.pushViewController(workoutVC, animated: true)
      workoutVC.workout = workout
    case .Custom:
      navigationController?.pushViewController(workoutDesignerVC, animated: true)
    default:
      navigationController?.pushViewController(workoutVC, animated: true)
      workoutVC.workout = workout
    }
  }
  
}
