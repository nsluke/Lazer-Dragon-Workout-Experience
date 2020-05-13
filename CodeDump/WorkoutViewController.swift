//
//  WorkoutViewController.swift
//  CodeDump
//
//  Created by Luke Solomon on 5/4/20.
//  Copyright © 2020 Observatory. All rights reserved.
//
// =================
// |               |
// |               |
// |               |
// |               |
// |               |
// |               |
// |               |
// |               |
// =================



import UIKit


class WorkoutViewController:UIViewController {
  
  var workout:Workout?
  
  var stackView = UIStackView()
  var workoutView = UIImageView()
  var workoutLabel = UILabel()
  var timerLabel = UILabel()
  var button = UIButton()
  
  var timer = Timer()
  var counter = 0.0
  var isPlaying = false
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
        
    guard let workout = workout else {
      fatalError("You must pass a workout to show this view controller")
    }
    
    title = workout.name
    
    counter = Double(workout.length)
    navigationItem.largeTitleDisplayMode = .never
    
    setupViews()
  }
  
  func setupViews() {
    view.backgroundColor = UIColor.OutrunDarkerGray
    stackView.backgroundColor = UIColor.OutrunDarkerGray
    stackView.isHidden = true
    
    view.addSubview(stackView)
    stackView.addArrangedSubview(workoutView)
    stackView.addArrangedSubview(timerLabel)
    stackView.addArrangedSubview(button)
    
    stackView.alignment = .center
    stackView.distribution = .equalCentering
    stackView.axis = .vertical
    
    stackView.translatesAutoresizingMaskIntoConstraints   = false
    workoutView.translatesAutoresizingMaskIntoConstraints = false
    timerLabel.translatesAutoresizingMaskIntoConstraints  = false
    button.translatesAutoresizingMaskIntoConstraints      = false
    
    timerLabel.text = String(counter)
    timerLabel.font = UIFont(name: "Pixel-01", size: 50) ?? UIFont.systemFont(ofSize: 30)
    timerLabel.textColor = UIColor.OutrunYellow
    
    button.setAttributedTitle(
      NSAttributedString(
        string: "Start",
        attributes: [
          .foregroundColor: UIColor.OutrunLaserBlue,
          .font : UIFont(name: "Pixel-01", size: 50) ?? UIFont.systemFont(ofSize: 18)
        ]
      ),
      for: .normal
    )
    button.addTarget(self, action: #selector(self.playPauseButtonTapped), for: .touchUpInside)
    button.layer.cornerRadius = 3
    button.titleEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    button.backgroundColor = UIColor.darkGray

    workoutView.image = #imageLiteral(resourceName: "situp")
    
    NSLayoutConstraint.activate([
      stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      stackView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
      stackView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
      button.widthAnchor.constraint(equalToConstant: 140),
      button.heightAnchor.constraint(equalToConstant: 80)
    ])
    
    view.backgroundColor = UIColor.white
  }
  
  //tapHandler - play pause
  @objc func playPauseButtonTapped() {
    
    button.setTitle("Stop", for: .normal)
    
  }
  
  
}

