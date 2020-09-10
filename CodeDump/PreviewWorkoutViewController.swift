//
//  PreviewWorkoutViewController.swift
//  CodeDump
//
//  Created by Luke Solomon on 9/2/20.
//  Copyright © 2020 Observatory. All rights reserved.
//

import UIKit

class PreviewWorkoutViewController:OutrunViewController {

  // MARK: Interface
  var tableView = UITableView()
  
  // MARK: Properties
  var viewModel:PreviewWorkoutViewModel? = nil
  
  
  // MARK: View Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    self.setupViews()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
  }
  
  func setupViews() {
    viewModel?.delegate = self
    
    navigationController?.navigationBar.prefersLargeTitles = true
    title = viewModel?.workout?.name 
    navigationController?.navigationBar.backgroundColor = UIColor.OutrunDarkerGray
    navigationController?.navigationBar.barTintColor = UIColor.OutrunDarkerGray

    view.backgroundColor = UIColor.OutrunDarkerGray
    navigationController?.navigationBar.titleTextAttributes = [
      .foregroundColor : UIColor.OutrunLaserBlue,
      .font : UIFont(name: "OutrunFuture", size: 18) ?? UIFont.systemFont(ofSize: 18)
    ]
    
    navigationController?.navigationBar.largeTitleTextAttributes = [
      .foregroundColor : UIColor.OutrunLaserBlue,
      .font : UIFont(name: "OutrunFuture", size: 30) ?? UIFont.systemFont(ofSize: 30)
    ]
    
    tableView.delegate = self.viewModel
    tableView.dataSource = self.viewModel
    tableView.register(PreviewWorkoutCell.self, forCellReuseIdentifier: "PreviewCell")
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
}

extension PreviewWorkoutViewController: PreviewWorkoutViewModelDelegate {
  
  func doneButtonTapped() {
    let workoutVC = WorkoutViewController()
    workoutVC.workout = self.viewModel?.workout

    navigationController?.pushViewController(workoutVC, animated: true)
  }
  
  func refreshTable() {
    self.tableView.reloadData()
  }
}
