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

  var routineDesignerDelegate:RoutineDesignerCellDelegate?
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
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
    tableViewHandler = RoutineDesignerTableViewHandler.init(tableView: tableView)
    tableView.delegate = tableViewHandler
    tableView.dataSource = tableViewHandler
    tableView.register(RoutineDesignerTableViewCell.self, forCellReuseIdentifier: "RoutineCell") //TO DO: Get this working!
    tableView.register(IntervalVisualizationCell.self, forCellReuseIdentifier: "VisualizationCell") //TO DO: Get this working!
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
