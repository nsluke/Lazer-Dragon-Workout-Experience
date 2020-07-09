//
//  ExercisesDesignerViewController.swift
//  CodeDump
//
//  Created by Luke Solomon on 7/6/20.
//  Copyright © 2020 Observatory. All rights reserved.
//

import UIKit


protocol ExercisesDesignerCellDelegate {
  func returnExercise(workoutModel:WorkoutModel)
}

class ExercisesDesignerViewController: OutrunViewController {
  
//  var exercisesDesignerView:ExercisesDesignerView?
  var delegate:ExercisesDesignerCellDelegate?
  var workout:WorkoutModel?
  
  var containerView = OutrunStackView()
  var textField = OutrunTextField()
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
//    let exercisesDesignerViewModel = ExercisesDesignerViewModel(designerViewDelegate: self)
//    let view = ExercisesDesignerView()
//    self.exercisesDesignerView = view
//    self.exercisesDesignerView?.configure(viewModel: exercisesDesignerViewModel)
    
    setupViews()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    self.workout?.name = textField.text!
    self.delegate?.returnExercise(workoutModel: workout!)
  }
  
  func setupViews() {
    self.title = "Name your Exercise"
    navigationItem.largeTitleDisplayMode = .never
    navigationItem.backBarButtonItem?.tintColor = UIColor.OutrunLaserBlue
    navigationController?.navigationBar.backgroundColor = UIColor.OutrunDarkerGray
    navigationController?.navigationBar.barTintColor = UIColor.OutrunDarkerGray
    
    view.backgroundColor = UIColor.OutrunDarkerGray
    
    // TableView
    view.addSubview(containerView)
    containerView.translatesAutoresizingMaskIntoConstraints = false
    containerView.addBackground(color: UIColor.OutrunDarkerGray)
    containerView.axis = .vertical
    containerView.distribution = .fillProportionally
    containerView.alignment = .center
    
    textField.translatesAutoresizingMaskIntoConstraints = false
    textField.customizeWithStandardValues(placeholder: "_")
    textField.delegate = self
    
    containerView.addArrangedSubview(textField)
    
    NSLayoutConstraint.activate([
      containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      containerView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
      containerView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
      
      textField.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 12.0),
      textField.rightAnchor.constraint(equalTo: containerView.rightAnchor, constant: 12.0)
    ])
  }
}

extension ExercisesDesignerViewController: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    guard let textFieldText = textField.text else {
      return true
    }
    
    self.workout?.name = textFieldText
    textField.resignFirstResponder()

    return true
  }
  
  func textFieldDidBeginEditing(_ textField: UITextField) {
    guard let textFieldText = textField.text else {
      return
    }
    
    self.workout?.name = textFieldText
  }
  
  func textFieldDidEndEditing(_ textField: UITextField) {
    guard let textFieldText = textField.text else {
      return
    }
    
    self.workout?.name = textFieldText
  }
  
  func textFieldShouldClear(_ textField: UITextField) -> Bool {
    guard let textFieldText = textField.text else {
      return true
    }
    
    self.workout?.name = ""

    return true
  }
  
  
}
