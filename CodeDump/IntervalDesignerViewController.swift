//
//  IntervalDesignerViewController.swift
//  CodeDump
//
//  Created by Luke Solomon on 5/11/20.
//  Copyright © 2020 Observatory. All rights reserved.
//

import UIKit

protocol IntervalDesignerDelegate {
  func finishedEditing(workout:WorkoutModel)
}

class IntervalDesignerViewController: OutrunViewController {
  
  var workout:WorkoutModel?
  var delegate:IntervalDesignerDelegate?
  
  let containerView = UIStackView()
  
  // Interval Length
  var intervalLengthPickerHandler:WorkoutPickerHandler!
  let intervalLengthContainerView = UIStackView()
  let intervalLengthLabel = OutrunLabel()
  let intervalLengthPickerView = OutrunPickerView()

  // Rest Length
  var restLengthPickerHandler:WorkoutPickerHandler!
  let restLengthContainerView = UIStackView()
  let restLengthLabel = OutrunLabel()
  let restLengthPickerView = OutrunPickerView()
  
  // Number of Intervals
  var numberOfIntervalsPickerHandler:WorkoutPickerHandler!
  let numberOfIntervalsContainerView = UIStackView()
  let numberOfIntervalsLabel = OutrunLabel()
  let numberOfIntervalsPickerView = OutrunPickerView()
  
  // Number of Sets
  var numberOfSetsPickerHandler:WorkoutPickerHandler!
  let numberOfSetsContainerView = UIStackView()
  let numberOfSetsLabel = OutrunLabel()
  let numberOfSetsPickerView = OutrunPickerView()
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    title = "Choose Your Destiny"
    navigationItem.largeTitleDisplayMode = .never
    navigationItem.backBarButtonItem?.tintColor = UIColor.OutrunLaserBlue
    navigationController?.navigationBar.backgroundColor = UIColor.OutrunDarkerGray
    navigationController?.navigationBar.barTintColor = UIColor.OutrunDarkerGray
    
    setupViews()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    self.delegate?.finishedEditing(workout: workout!)
//    CoreDataHandler.shared.saveWorkouts(workoutModels: [workout!]) {
//      DispatchQueue.main.async {
//        super.viewDidDisappear(animated)
//      }
//    }
  }
  
  func setupViews() {
    view.addSubview(containerView)
    view.backgroundColor = UIColor.OutrunDarkerGray

    containerView.translatesAutoresizingMaskIntoConstraints = false
    containerView.axis = .vertical
    containerView.distribution = .fillEqually
    

    // Interval Length
    containerView.addArrangedSubview(intervalLengthContainerView)
    intervalLengthContainerView.addArrangedSubview(intervalLengthLabel)
    intervalLengthContainerView.addArrangedSubview(intervalLengthPickerView)
    intervalLengthContainerView.alignment = .center
    intervalLengthContainerView.distribution = .fill
    intervalLengthContainerView.axis = .vertical
    intervalLengthContainerView.translatesAutoresizingMaskIntoConstraints = false
    
    intervalLengthLabel.customize(text: "Interval Length", font: .Pixel, size: 30, textColor: UIColor.OutrunPaleYellow)
    intervalLengthLabel.translatesAutoresizingMaskIntoConstraints = false
    
    intervalLengthPickerView.outrunPickerViewType = .IntervalLength
    intervalLengthPickerView.translatesAutoresizingMaskIntoConstraints = false
    intervalLengthPickerHandler = WorkoutPickerHandler(pickerView: intervalLengthPickerView, workoutPickerDelegate: self)
    intervalLengthPickerView.dataSource = intervalLengthPickerHandler
    intervalLengthPickerView.delegate = intervalLengthPickerHandler
    intervalLengthPickerView.selectRow(workout!.intervalLength/5, inComponent: 0, animated: false)
    
    // Rest Length
    containerView.addArrangedSubview(restLengthContainerView)
    restLengthContainerView.addArrangedSubview(restLengthLabel)
    restLengthContainerView.addArrangedSubview(restLengthPickerView)
    restLengthContainerView.alignment = .center
    restLengthContainerView.distribution = .fill
    restLengthContainerView.axis = .vertical
    restLengthContainerView.translatesAutoresizingMaskIntoConstraints = false

    restLengthLabel.customize(text: "Rest Length", font: .Pixel, size: 30, textColor: UIColor.OutrunPaleYellow)
    restLengthLabel.translatesAutoresizingMaskIntoConstraints = false

    restLengthPickerView.outrunPickerViewType = .RestLength
    restLengthPickerView.translatesAutoresizingMaskIntoConstraints = false
    restLengthPickerHandler = WorkoutPickerHandler(pickerView: restLengthPickerView, workoutPickerDelegate: self)
    restLengthPickerView.dataSource = restLengthPickerHandler
    restLengthPickerView.delegate = restLengthPickerHandler
    restLengthPickerView.selectRow(workout!.restLength/5, inComponent: 0, animated: false)
    
    
    // Number of Intervals
    containerView.addArrangedSubview(numberOfIntervalsContainerView)
    numberOfIntervalsContainerView.addArrangedSubview(numberOfIntervalsLabel)
    numberOfIntervalsContainerView.addArrangedSubview(numberOfIntervalsPickerView)
    numberOfIntervalsContainerView.alignment = .center
    numberOfIntervalsContainerView.distribution = .fill
    numberOfIntervalsContainerView.axis = .vertical
    numberOfIntervalsContainerView.translatesAutoresizingMaskIntoConstraints = false
    
    numberOfIntervalsLabel.customize(text: "Number of Intervals", font: .Pixel, size: 30, textColor: UIColor.OutrunPaleYellow)
    numberOfIntervalsLabel.translatesAutoresizingMaskIntoConstraints = false
    
    numberOfIntervalsPickerView.outrunPickerViewType = .IntervalCount
    numberOfIntervalsPickerView.translatesAutoresizingMaskIntoConstraints = false
    numberOfIntervalsPickerHandler = WorkoutPickerHandler(pickerView: numberOfIntervalsPickerView, workoutPickerDelegate: self)
    numberOfIntervalsPickerView.dataSource = numberOfIntervalsPickerHandler
    numberOfIntervalsPickerView.delegate = numberOfIntervalsPickerHandler
    numberOfIntervalsPickerView.selectRow(workout!.numberOfIntervals, inComponent: 0, animated: false)

    
    // Number of Sets
    containerView.addArrangedSubview(numberOfSetsContainerView)
    numberOfSetsContainerView.addArrangedSubview(numberOfSetsLabel)
    numberOfSetsContainerView.addArrangedSubview(numberOfSetsPickerView)
    numberOfSetsContainerView.alignment = .center
    numberOfSetsContainerView.distribution = .fill
    numberOfSetsContainerView.axis = .vertical
    numberOfSetsContainerView.translatesAutoresizingMaskIntoConstraints = false
    
    numberOfSetsLabel.customize(text: "Number of Sets", font: .Pixel, size: 30, textColor: UIColor.OutrunPaleYellow)
    numberOfSetsLabel.translatesAutoresizingMaskIntoConstraints = false
    
    numberOfSetsPickerView.outrunPickerViewType = .SetCount
    numberOfSetsPickerView.translatesAutoresizingMaskIntoConstraints = false
    numberOfSetsPickerHandler = WorkoutPickerHandler(pickerView: numberOfSetsPickerView, workoutPickerDelegate: self)
    numberOfSetsPickerView.dataSource = numberOfSetsPickerHandler
    numberOfSetsPickerView.delegate = numberOfSetsPickerHandler
    numberOfSetsPickerView.selectRow(workout!.numberOfSets, inComponent: 0, animated: false)
    
    
    NSLayoutConstraint.activate([
      containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
      containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      containerView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
      containerView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
      
      intervalLengthContainerView.leftAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.leftAnchor),
      intervalLengthContainerView.rightAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.rightAnchor),
      intervalLengthLabel.heightAnchor.constraint(equalToConstant: 30),
      intervalLengthPickerView.heightAnchor.constraint(equalToConstant: 80),
      
      restLengthContainerView.leftAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.leftAnchor),
      restLengthContainerView.rightAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.rightAnchor),
      restLengthLabel.heightAnchor.constraint(equalToConstant: 30),
      restLengthPickerView.heightAnchor.constraint(equalToConstant: 80),
      
      numberOfIntervalsContainerView.leftAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.leftAnchor),
      numberOfIntervalsContainerView.rightAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.rightAnchor),
      numberOfIntervalsLabel.heightAnchor.constraint(equalToConstant: 30),
      numberOfIntervalsPickerView.heightAnchor.constraint(equalToConstant: 80),
      
      numberOfSetsContainerView.leftAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.leftAnchor),
      numberOfSetsContainerView.rightAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.rightAnchor),
      numberOfSetsLabel.heightAnchor.constraint(equalToConstant: 30),
      numberOfSetsPickerView.heightAnchor.constraint(equalToConstant: 80)
    ])
  }
  
}

extension IntervalDesignerViewController : WorkoutPickerDelegate {
  
  func valueChanged(in picker: UIPickerView, toNewValue: Int) {
    
    if picker === intervalLengthPickerView {
      self.workout?.intervalLength = toNewValue * 5
      
    } else if picker === restLengthPickerView {
      self.workout?.restLength = toNewValue * 5
      
    } else if picker === numberOfIntervalsPickerView {
      self.workout?.numberOfIntervals = toNewValue
      
    } else if picker === numberOfSetsPickerView {
      self.workout?.numberOfSets = toNewValue
      
    }
      
  }
  
  
}
