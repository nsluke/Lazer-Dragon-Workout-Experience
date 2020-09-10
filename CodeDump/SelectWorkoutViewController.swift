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
  
  var workoutModels = [WorkoutModel]()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupViews()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    
    DataHandler.shared.getWorkoutModels { (result) in
      if case .success(let workouts) = result {
        if self.workoutModels != workouts {
          self.workoutModels = workouts
          DispatchQueue.main.async {
            self.tableView.reloadData()
          }
        }
      } else if case .failure = result {
        print("SelectWorkoutViewController - viewDidLoad: Error fetching Data for Table View")
      }
    }
    
  }
  
  func setupViews() {
    navigationController?.navigationBar.prefersLargeTitles = true
    title = "Select your Workout"
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
    
    navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.addItemTapped))
    navigationItem.rightBarButtonItem?.tintColor = UIColor.OutrunLaserBlue
    
    tableView.dataSource = self
    tableView.delegate = self
    tableView.register(OutrunTableViewCell.self, forCellReuseIdentifier: "CellID")
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
    return self.workoutModels.count
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "CellID") as? OutrunTableViewCell
    
    guard let safeCell = cell else { return UITableViewCell() }
    
    var viewModel = OutrunTableViewCellModel(
      titleText: self.workoutModels[indexPath.row].name,
      font: OutrunFonts.Pixel,
      fontSize: 34,
      textColor: UIColor.OutrunPaleYellow
    )

    if self.workoutModels[indexPath.row].name.containsNonEnglishCharacters() {
      viewModel.fontSize = 34
    }
    
    
    safeCell.configure(viewModel: viewModel)
    
    safeCell.selectionStyle = .default
    
    let selectedBackgroundView = UIView.init()
    selectedBackgroundView.backgroundColor = UIColor.OutrunDarkGray
    safeCell.selectedBackgroundView = selectedBackgroundView
    
    return safeCell
  }
}

extension SelectWorkoutViewController:UITableViewDelegate {
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 50
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
    let viewModel = PreviewWorkoutViewModel()
    viewModel.workout = self.workoutModels[indexPath.row]
    
    let previewWorkoutVC = PreviewWorkoutViewController()
    previewWorkoutVC.viewModel = viewModel
    previewWorkoutVC.modalPresentationStyle = .overCurrentContext
    navigationController?.pushViewController(previewWorkoutVC, animated: true)
  }
  
  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      let workoutToRemove = self.workoutModels[indexPath.row]
      self.workoutModels.remove(at: indexPath.row)
      DataHandler.shared.deleteWorkout(workoutName: workoutToRemove.name) {
        DispatchQueue.main.async {}
      }
      tableView.deleteRows(at: [indexPath], with: .fade)
    }
  }
  
}
