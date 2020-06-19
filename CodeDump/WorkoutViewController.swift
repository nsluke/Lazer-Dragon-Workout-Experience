//
//  WorkoutViewController.swift
//  CodeDump
//
//  Created by Luke Solomon on 5/4/20.
//  Copyright © 2020 Observatory. All rights reserved.
//
//  ==================================
// |                                  |
// |elapsed   split timer    remaining|
// |                                  |
// |                                  |
// |                                  |
// |                                  |
// |           |Character|            |
// |          Exercise Title          |
// |                                  |
// |                                  |
// |                                  |
// |                                  |
// |                                  |
// |                                  |
// |                                  |
// |music         stop          finish|
// |                                  |
//  ==================================



import UIKit

protocol WorkoutDelegate: WorkoutViewController {
  func updateTimer(time: String, remainingTime: String, elapsedTime: String)
  func updateStartStopButton(isPaused: Bool)
  func updateExerciseLabel(text: String)
}

class WorkoutViewController:OutrunViewController {
  
  var workout:WorkoutModel!
  
  var handler:WorkoutHandler!
  
  var containerView = OutrunStackView()
  
  var timerStackView = OutrunStackView()
  var elapsedTimerLabel = OutrunLabel()
  var splitTimerLabel = OutrunLabel()
  var remainingTimerLabel = OutrunLabel()

  var workoutView = UIImageView()
  var exerciseTitleLabel = OutrunLabel()

  var controlStackView = OutrunStackView()
  var musicButton = UIButton()
  var startStopButton = UIButton()
  var endButton = UIButton()
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
        
    guard let workout = workout else {
      fatalError("You must pass a workout to show this view controller")
    }
    
    handler = WorkoutHandler(workout: workout, delegate: self)
    
    title = handler.workout.name
    
    navigationItem.largeTitleDisplayMode = .never

    setupViews()
    self.handler.updateTimer()
  }
  
  func setupViews() {
    self.navigationController?.navigationBar.backgroundColor = UIColor.OutrunDarkGray

    // Container View
    view.addSubview(containerView)
    view.backgroundColor = UIColor.OutrunDarkerGray
    
    containerView.translatesAutoresizingMaskIntoConstraints = false
    containerView.axis = .vertical
    containerView.backgroundColor = UIColor.OutrunDarkerGray
    containerView.distribution = .fillProportionally
    containerView.alignment = .center
    
    
    // Timers
    containerView.addArrangedSubview(timerStackView)
    timerStackView.addArrangedSubview(elapsedTimerLabel)
    timerStackView.addArrangedSubview(splitTimerLabel)
    timerStackView.addArrangedSubview(remainingTimerLabel)
    timerStackView.alignment = .center
    timerStackView.distribution = .equalSpacing
    timerStackView.axis = .horizontal
    timerStackView.translatesAutoresizingMaskIntoConstraints = false
    
    
    // elapsedTimerLabel
    elapsedTimerLabel.font = UIFont(name: "Pixel-01", size: 20) ?? UIFont.systemFont(ofSize: 30)
    elapsedTimerLabel.textColor = UIColor.OutrunLaserGreen
    
    
    // SplitTimer
    splitTimerLabel.font = UIFont(name: "Pixel-01", size: 70) ?? UIFont.systemFont(ofSize: 30)
    splitTimerLabel.textColor = UIColor.OutrunPaleYellow
    
    
    // remainingTimerLabel
    remainingTimerLabel.font = UIFont(name: "Pixel-01", size: 20) ?? UIFont.systemFont(ofSize: 30)
    remainingTimerLabel.textColor = UIColor.OutrunSoftRed
    
    
    // Exercise
    containerView.addArrangedSubview(workoutView)
    containerView.addArrangedSubview(exerciseTitleLabel)
    workoutView.translatesAutoresizingMaskIntoConstraints = false
    //    workoutView.image = #imageLiteral(resourceName: "situp")
    exerciseTitleLabel.translatesAutoresizingMaskIntoConstraints = false
    exerciseTitleLabel.font = UIFont(name: "Pixel-01", size: 30) ?? UIFont.systemFont(ofSize: 30)
    exerciseTitleLabel.textColor = UIColor.OutrunPaleYellow
        
    
    // controls
    containerView.addArrangedSubview(controlStackView)
    controlStackView.addArrangedSubview(musicButton)
    controlStackView.addArrangedSubview(startStopButton)
    controlStackView.addArrangedSubview(endButton)
    controlStackView.alignment = .center
    controlStackView.distribution = .equalSpacing
    controlStackView.axis = .horizontal
    controlStackView.spacing = CGFloat(20.0)
    
    
    // musicButton
    
    
    // startStopButton
    startStopButton.setAttributedTitle(
      NSAttributedString(
        string: "Start",
        attributes: [
          .foregroundColor: UIColor.OutrunLaserBlue,
          .font : UIFont(name: "Pixel-01", size: 40) ?? UIFont.systemFont(ofSize: 18)
        ]
      ),
      for: .normal
    )
    startStopButton.addTarget(self, action: #selector(self.playPauseButtonTapped), for: .touchUpInside)
    startStopButton.layer.cornerRadius = 3
    startStopButton.titleEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    startStopButton.backgroundColor = UIColor.darkGray

    
    // finishButton
    endButton.setAttributedTitle(
      NSAttributedString(
        string: "End",
        attributes: [
          .foregroundColor: UIColor.OutrunLaserBlue,
          .font : UIFont(name: "Pixel-01", size: 30) ?? UIFont.systemFont(ofSize: 18)
        ]
      ),
      for: .normal
    )
    endButton.addTarget(self, action: #selector(self.endButtonTapped), for: .touchUpInside)
    endButton.layer.cornerRadius = 3
    endButton.titleEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
    endButton.backgroundColor = UIColor.darkGray
    
    
    NSLayoutConstraint.activate([
      containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      containerView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
      containerView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
      
      containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      timerStackView.leftAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.leftAnchor, constant: 8),
      timerStackView.rightAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.rightAnchor, constant: -8),
//      elapsedTimerLabel.centerXAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.centerXAnchor),
      
      startStopButton.widthAnchor.constraint(equalToConstant: 140),
      startStopButton.heightAnchor.constraint(equalToConstant: 80),
      
      endButton.widthAnchor.constraint(equalToConstant: 70),
      endButton.heightAnchor.constraint(equalToConstant: 40)
    ])
    
    view.backgroundColor = UIColor.white
  }
  
  func setTimerText(label: OutrunLabel, time: String) {
    label.text = time
  }
  
  //tapHandler - play pause
  @objc func playPauseButtonTapped() {
    handler.playPauseTapped()
  }
    
  func handleTimerEnded() {
    
  }
  
  @objc func endButtonTapped() {
    // present an alert?
  }
  
}

extension WorkoutViewController : WorkoutDelegate {
  func updateExerciseLabel(text: String) {
    exerciseTitleLabel.text = text
  }
  
  func updateStartStopButton(isPaused: Bool) {
    var buttonText = ""
    
    if isPaused {
      buttonText = "Paused"
    } else {
      buttonText = "Continue"
    }
    
    startStopButton.setAttributedTitle(
      NSAttributedString(
        string: buttonText,
        attributes: [
          .foregroundColor: UIColor.OutrunLaserBlue,
          .font : UIFont(name: "Pixel-01", size: 40) ?? UIFont.systemFont(ofSize: 18)
        ]
      ),
      for: .normal
    )
  }
  
  func updateTimer(time: String, remainingTime: String, elapsedTime: String) {
    setTimerText(label: self.elapsedTimerLabel, time: elapsedTime)
    setTimerText(label: self.splitTimerLabel, time: time)
    setTimerText(label: self.remainingTimerLabel, time: remainingTime)
  }
  
  
}
