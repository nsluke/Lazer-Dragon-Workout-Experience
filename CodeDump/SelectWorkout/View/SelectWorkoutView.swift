//
// Created by VIPER
// Copyright (c) 2020 VIPER. All rights reserved.
//

import Foundation
import UIKit

class SelectWorkoutView: OutrunViewController, SelectWorkoutViewProtocol {
  
  var presenter: SelectWorkoutPresenterProtocol?
  
  var tableView:UITableView = {
    let table = UITableView()
    
    table.register(OutrunTableViewCell.self, forCellReuseIdentifier: "CellID")
    table.translatesAutoresizingMaskIntoConstraints = false
    table.separatorStyle = .none
    table.backgroundColor = UIColor.OutrunDarkerGray
    
    return table
  }()
  
  var workoutModels:[WorkoutModel]  = [] {
    didSet {
      guard oldValue != workoutModels else { return }
      
      tableView.reloadSections([0], with: .automatic)
    }
  }
  
  
  // MARK: - View Lifecycle
//  override func loadView() {
//    
//  }
//  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.hideBackButton()

    presenter?.viewDidLoad()

//    tableView.tableFooterView = UIView()
    setupViews()
  }
  
  func setupViews() {
    
    title = "Select your Workout"
    view.backgroundColor = UIColor.OutrunDarkerGray
    view.addSubview(tableView)
    tableView.dataSource = self
    tableView.delegate = self
    
    navigationController?.navigationBar.prefersLargeTitles = true
    navigationController?.navigationBar.backgroundColor = UIColor.OutrunDarkerGray
    navigationController?.navigationBar.barTintColor = UIColor.OutrunDarkerGray
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
    
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      tableView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor)
    ])
  }
  
  @objc func addItemTapped(sender:UIButton) {
    let routineDesignerVC = RoutineDesignerViewController()
    navigationController?.present(routineDesignerVC, animated: true)
  }
  
  // MARK: - Presenter Input
  func loadWorkouts(with workouts:[WorkoutModel]) {
    self.workoutModels = workouts
  }
  
}
extension SelectWorkoutView:UITableViewDataSource {
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

extension SelectWorkoutView:UITableViewDelegate {
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 50
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    self.presenter?.showWorkoutDetail(forWorkout: workoutModels[indexPath.row])
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
