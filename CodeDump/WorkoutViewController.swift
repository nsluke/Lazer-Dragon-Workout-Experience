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

enum WorkoutSegment {
  case Stopped
  case Paused
  case Warmup
  case Interval
  case Rest
  case Cooldown
  case End
}

class WorkoutViewController:UIViewController {
  
  var workout:WorkoutModel?
  
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
  var finishButton = UIButton()

  var timer = Timer()
  var counter = 0
  var isPlaying = false
  var workoutState = WorkoutSegment.Stopped
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
        
    guard let workout = workout else {
      fatalError("You must pass a workout to show this view controller")
    }
    
    title = workout.name
    
    navigationItem.largeTitleDisplayMode = .never
    navigationItem.backBarButtonItem?.tintColor = UIColor.OutrunLaserBlue
    navigationItem.leftBarButtonItem?.tintColor = UIColor.OutrunLaserBlue
    
    setupViews()
    counter = workout.length
    setTimerText(label: self.elapsedTimerLabel)
    setTimerText(label: self.splitTimerLabel)
    setTimerText(label: self.remainingTimerLabel)  }
  
  func setupViews() {
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
    elapsedTimerLabel.text = "elapsed"
    elapsedTimerLabel.font = UIFont(name: "Pixel-01", size: 20) ?? UIFont.systemFont(ofSize: 30)
    elapsedTimerLabel.textColor = UIColor.OutrunLaserGreen
    
    
    // SplitTimer
    splitTimerLabel.text = String(counter)
    splitTimerLabel.font = UIFont(name: "Pixel-01", size: 70) ?? UIFont.systemFont(ofSize: 30)
    splitTimerLabel.textColor = UIColor.OutrunYellow
    
    
    // remainingTimerLabel
    remainingTimerLabel.text = "remaining"
    remainingTimerLabel.font = UIFont(name: "Pixel-01", size: 20) ?? UIFont.systemFont(ofSize: 30)
    remainingTimerLabel.textColor = UIColor.OutrunSoftRed
    
    
    // Exercise
    containerView.addArrangedSubview(workoutView)
    containerView.addArrangedSubview(exerciseTitleLabel)
    workoutView.translatesAutoresizingMaskIntoConstraints = false
    //    workoutView.image = #imageLiteral(resourceName: "situp")
    exerciseTitleLabel.translatesAutoresizingMaskIntoConstraints = false
    exerciseTitleLabel.text = "Exercise"
    exerciseTitleLabel.font = UIFont(name: "Pixel-01", size: 30) ?? UIFont.systemFont(ofSize: 30)
    exerciseTitleLabel.textColor = UIColor.OutrunYellow
        
    
    // controls
    containerView.addArrangedSubview(controlStackView)
    controlStackView.addArrangedSubview(musicButton)
    controlStackView.addArrangedSubview(startStopButton)
    controlStackView.addArrangedSubview(finishButton)
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
    finishButton.setAttributedTitle(
      NSAttributedString(
        string: "End",
        attributes: [
          .foregroundColor: UIColor.OutrunLaserBlue,
          .font : UIFont(name: "Pixel-01", size: 30) ?? UIFont.systemFont(ofSize: 18)
        ]
      ),
      for: .normal
    )
    finishButton.addTarget(self, action: #selector(self.finishButtonTapped), for: .touchUpInside)
    finishButton.layer.cornerRadius = 3
    finishButton.titleEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
    finishButton.backgroundColor = UIColor.darkGray
    
    
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
      
      finishButton.widthAnchor.constraint(equalToConstant: 70),
      finishButton.heightAnchor.constraint(equalToConstant: 40)
    ])
    
    view.backgroundColor = UIColor.white
  }
  
  
  @objc func updateTimer() {
    if counter < 1 {
      counter = 0
      handleTimerEnded()
    } else {
      counter -= 1
    }
    
    setTimerText(label: self.elapsedTimerLabel)
    setTimerText(label: self.splitTimerLabel)
    setTimerText(label: self.remainingTimerLabel)
  }
  
  func setTimerText(label: OutrunLabel) {
    let hours = counter/360
    let minutes = counter/60
    let seconds = counter
    
    var formattedTimeString = ""
    
    if hours < 1 {
      formattedTimeString = String(format: "%02i:%02i", minutes, seconds)
    } else {
      formattedTimeString = String(format: "%02i:%02i:%02i", hours, minutes, seconds)
    }
    
    label.text = formattedTimeString
  }
  
  //tapHandler - play pause
  @objc func playPauseButtonTapped() {
    
    if isPlaying {
      stopTimer()
    } else {
      startTimer()
    }
    
    self.isPlaying = !self.isPlaying
  }
  

  func startTimer() {
    startStopButton.setAttributedTitle(
      NSAttributedString(
        string: "Pause",
        attributes: [
          .foregroundColor: UIColor.OutrunLaserBlue,
          .font : UIFont(name: "Pixel-01", size: 40) ?? UIFont.systemFont(ofSize: 18)
        ]
      ),
      for: .normal
    )
    timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
  }
  
  func stopTimer() {
    startStopButton.setAttributedTitle(
      NSAttributedString(
        string: "Continue",
        attributes: [
          .foregroundColor: UIColor.OutrunLaserBlue,
          .font : UIFont(name: "Pixel-01", size: 40) ?? UIFont.systemFont(ofSize: 18)
        ]
      ),
      for: .normal
    )
    timer.invalidate()
  }
  
  func handleTimerEnded() {
    
  }
  
  @objc func finishButtonTapped() {
    // present an alert?
  }
  
}

