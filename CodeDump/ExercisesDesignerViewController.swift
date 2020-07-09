//
//  ExercisesDesignerViewController.swift
//  CodeDump
//
//  Created by Luke Solomon on 7/6/20.
//  Copyright © 2020 Observatory. All rights reserved.
//

import UIKit


protocol ExercisesDesignerCellDelegate {
  func returnExercise(exercise:String)
}

class ExercisesDesignerViewController: UIViewController {
  
  var exercisesDesignerView:ExercisesDesignerView?
  var delegate:ExercisesDesignerCellDelegate?
  
  var containerView = OutrunStackView()
  var textField = OutrunTextField()
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let exercisesDesignerViewModel = ExercisesDesignerViewModel(designerViewDelegate: self)
    let view = ExercisesDesignerView()
    self.exercisesDesignerView = view
    self.exercisesDesignerView?.configure(viewModel: exercisesDesignerViewModel)
  }
  
  func setupViews() {
    self.title = "Design your Workout"
    navigationItem.largeTitleDisplayMode = .never
    navigationItem.backBarButtonItem?.tintColor = UIColor.OutrunLaserBlue
    navigationController?.navigationBar.backgroundColor = UIColor.OutrunDarkerGray
    navigationController?.navigationBar.barTintColor = UIColor.OutrunDarkerGray
    
    view.backgroundColor = UIColor.OutrunDarkerGray
    
    // TableView

    containerView.translatesAutoresizingMaskIntoConstraints = false
    containerView.addBackground(color: UIColor.OutrunDarkerGray)
    view.addSubview(containerView)
    textField.translatesAutoresizingMaskIntoConstraints = false

    containerView.addArrangedSubview(textField)
    
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      tableView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor)
    ])
  }
  

  
  
}

extension ExercisesDesignerViewController:ExercisesDesignerViewDelegate {
  func doneButtonTapped(text: String) {
    self.delegate?.returnExercise(exercise: text)
    navigationController?.popViewController(animated: true)
  }
}
