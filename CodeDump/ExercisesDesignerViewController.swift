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
  
  var delegate:ExercisesDesignerCellDelegate?
  var workout:WorkoutModel?
  
  var exerciseName = String()
  
  var exerciseNameLabel = OutrunLabel()
  var textField = OutrunTextField(placeholder: "_")

  var doneButton = OutrunButton(title: "Done", font: .Future, size: 40.0, textColor: .OutrunLaserBlue, backgroundColor: .OutrunBlack, cornerRadius: 5.0)
  

  override func viewDidLoad() {
    super.viewDidLoad()
    setupViews()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
//    self.workout?.name = textField.text!
//    self.delegate?.returnExercise(workoutModel: workout!)
  }
  
  func setupViews() {
    self.title = "Name your Exercise"
    
    navigationItem.largeTitleDisplayMode = .never

    textField.delegate = self
    view.addSubview(textField)
    
    textField.anchor(
      top: nil,
      left: view.safeAreaLayoutGuide.leftAnchor,
      bottom: nil,
      right: view.safeAreaLayoutGuide.rightAnchor,
      paddingTop: 0,
      paddingLeft: 16,
      paddingBottom: 0,
      paddingRight: 16,
      width: 0,
      height: 60,
      enableInsets: true
    )
    
    textField.centerInSuperview()
    view.addSubview(doneButton)
    
    doneButton.anchor(
      top: textField.bottomAnchor,
      left: nil,
      bottom: nil,
      right: nil,
      paddingTop: 20,
      paddingLeft: 0,
      paddingBottom: 0,
      paddingRight: 0,
      width: 150,
      height: 80,
      enableInsets: true
    )
    doneButton.centerXInSuperview()
    doneButton.addTarget(self, action: #selector(handleDoneButtonTapped(sender:)), for: .touchUpInside)
  }
  
  @objc func handleDoneButtonTapped(sender:UIButton!) {
    if let safeWorkout = workout {
      safeWorkout.exercises.append(
        ExerciseModel(
          order: 0, //todo: 
          name: textField.text ?? "",
          image: UIImage(),
          splitLength: 0
        )
      )
      delegate?.returnExercise(workoutModel: safeWorkout)
      navigationController?.popViewController(animated: true)
    }
  }
  
}

extension ExercisesDesignerViewController: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    guard let textFieldText = textField.text else {
      return true
    }
    
    self.exerciseName = textFieldText
    textField.resignFirstResponder()

    return true
  }
  
  func textFieldDidBeginEditing(_ textField: UITextField) {
    guard let textFieldText = textField.text else {
      return
    }
    
    self.exerciseName = textFieldText
  }
  
  func textFieldDidEndEditing(_ textField: UITextField) {
    guard let textFieldText = textField.text else {
      return
    }
    
    self.exerciseName = textFieldText
  }
  
  func textFieldShouldClear(_ textField: UITextField) -> Bool {
    guard let textFieldText = textField.text else {
      return true
    }
    
    self.exerciseName = ""

    return true
  }
  
  
}
