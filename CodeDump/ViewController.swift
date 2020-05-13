//
//  ViewController.swift
//  CodeDump
//
//  Created by Luke Solomon on 5/1/20.
//  Copyright © 2020 Observatory. All rights reserved.
//


import UIKit


class ViewController: UIViewController {
  
  var tableView:UITableView = UITableView.init()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
    
    navigationController?.navigationBar.prefersLargeTitles = true
    title = "Select your Workout"
    
    view.backgroundColor = UIColor.OutrunDarkerGray
    navigationController?.navigationBar.tintColor = UIColor.OutrunDarkGray
    navigationController?.navigationBar.titleTextAttributes = [
      .foregroundColor: UIColor.OutrunLaserBlue,
      .font : UIFont(name: "OutrunFuture", size: 18) ?? UIFont.systemFont(ofSize: 18)
    ]
    navigationController?.navigationBar.largeTitleTextAttributes = [
      .foregroundColor: UIColor.OutrunLaserBlue,
      .font : UIFont(name: "OutrunFuture", size: 30) ?? UIFont.systemFont(ofSize: 30)
    ]
    navigationController?.navigationBar.barTintColor = UIColor.OutrunDarkGray
    navigationController?.navigationBar.backgroundColor = UIColor.OutrunDarkGray
    navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.addItemTapped))
    
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
    
  }
  
}
extension ViewController:UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return Constants.Workouts.count
  }
  
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "CellID")
    
    cell?.textLabel?.text = Constants.Workouts[indexPath.row].name
    cell?.textLabel?.textColor = UIColor.OutrunYellow
    
    cell?.textLabel?.font = UIFont(name: "Pixel-01", size: 20) ?? UIFont.systemFont(ofSize: 15)
    
    cell?.backgroundColor = UIColor.OutrunDarkerGray
    cell?.selectionStyle = .default
    
    let selectedBackgroundView = UIView.init()
    selectedBackgroundView.backgroundColor = UIColor.OutrunDarkGray
    cell?.selectedBackgroundView = selectedBackgroundView
    
    return cell!
  }
}

extension ViewController:UITableViewDelegate {
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    let workout = Constants.Workouts[indexPath.row]
    var workoutVC = WorkoutViewController()
    var workoutDesignerVC = IntervalDesignerViewController()
    
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
