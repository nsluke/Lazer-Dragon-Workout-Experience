//
// Created by VIPER
// Copyright (c) 2020 VIPER. All rights reserved.
//

import Foundation
import UIKit

class PreviewWorkoutView: OutrunViewController, PreviewWorkoutViewProtocol {
  
  var presenter: PreviewWorkoutPresenterProtocol?
  var workout:WorkoutModel?
  
  // MARK: Interface
  lazy var tableView:UITableView = {
    let table = UITableView()
    table.delegate = self
    table.dataSource = self
    table.register(PreviewWorkoutCell.self, forCellReuseIdentifier: "PreviewCell")
    table.translatesAutoresizingMaskIntoConstraints = false
    table.separatorStyle = .none
    table.backgroundColor = UIColor.OutrunDarkerGray
    return table
  }()
  
  
  override func loadView() {
    super.loadView()
    
    self.setupViews()
  }
  
  func setupViews() {
    navigationController?.navigationBar.prefersLargeTitles = true
    title = self.workout?.name
    navigationItem.backBarButtonItem?.tintColor = UIColor.OutrunLaserBlue
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
    
    view.addSubview(tableView)
    
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.topAnchor), // prevents large title glitches
      tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      tableView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor)
    ])
  }
}

extension PreviewWorkoutView: UITableViewDelegate {
  
  func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    if section == 3 { // last section
      let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 80))
      view.backgroundColor = UIColor.OutrunDarkerGray
      
      let button = OutrunButton(frame: CGRect(x: (tableView.frame.width/2) - 75, y: 0, width: 150, height: 80))
      view.addSubview(button)

      button.customize(
        text: "Done",
        font: .Future,
        size: 40,
        textColor: .OutrunLaserBlue
      )
      button.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
      
      return view
    } else {
      
      let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 20.0))
      view.backgroundColor = UIColor.OutrunDarkerGray
      
      return view
    }
  }
  
  func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    if section == 3 { // last section
      return 80.0
    } else {
      return 20.0
    }
  }
  
}

extension PreviewWorkoutView: UITableViewDataSource {
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 4
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    // sections:
    // 0 - Warmup
    // 1 - Cooldown
    // 2 - Number of Sets, cooldown between sets
    // 3 - Intervals
    
    if section == 0 {
      return 1
    } else if section == 1 {
      return 1
    } else if section == 2 {
      return 1
    } else if section == 3 {
      return (workout?.exercises.count ?? 0)
    } else {
      return 0
    }
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "PreviewCell", for: indexPath) as! PreviewWorkoutCell
    
    if indexPath.section == 0 {
      
      let viewModel = OutrunTableViewCellModel(
        titleText: "Warmup: \(String.timeToFormattedString(time: workout!.warmupLength))",
        font: .Pixel,
        fontSize: 24,
        textColor: .OutrunLaserGreen)
      
      cell.configure(viewModel: viewModel)
      
    } else if indexPath.section == 1 {
      
      let viewModel = OutrunTableViewCellModel(
        titleText: "Cooldown: \(String.timeToFormattedString(time: workout!.cooldownLength))",
        font: .Pixel,
        fontSize: 24,
        textColor: .OutrunLaserGreen)
      
      cell.configure(viewModel: viewModel)
      
    } else if indexPath.section == 2 {
      
      let viewModel = OutrunTableViewCellModel(
        titleText: "\(workout!.numberOfSets) sets, \(String.timeToFormattedString(time: workout!.restBetweenSetLength)) rest between each",
        font: .Pixel,
        fontSize: 24,
        textColor: .OutrunLaserGreen)
      
      cell.configure(viewModel: viewModel)
      
    } else if indexPath.section == 3 {
      
      var viewModel = OutrunTableViewCellModel(
        titleText: "",
        font: .Pixel,
        fontSize: 24,
        textColor: .OutrunPaleYellow
      )
      
      if indexPath.row == 0 {
        
        viewModel.titleText = "\(workout?.numberOfIntervals ?? 0) intervals, \(String.timeToFormattedString(time: workout!.intervalLength)) seconds each"
        viewModel.textColor = .OutrunLaserGreen
        
      } else if indexPath.row == 1 {
        
        viewModel.titleText = "\(workout!.restLength) seconds rest between each"
        viewModel.textColor = .OutrunLaserGreen
        
      } else {
        
        var text = "\(workout?.exercises[indexPath.row - 2].name ?? "")"
        if workout?.exercises[indexPath.row - 2].reps ?? 0 > 0 {
          text.append("x \(workout!.exercises[indexPath.row - 2].reps)")
        }
        viewModel.titleText = text
      }
      cell.configure(viewModel: viewModel)
    }
    
    return cell
  }
  
  @objc func doneButtonTapped() {
    presenter?.doneButtonTapped(workout: self.workout!)
  }
}
