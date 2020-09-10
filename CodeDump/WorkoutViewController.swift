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
// |           Exercise Title         |
// |                                  |
// |                                  |
// |                                  |
// |                                  |
// |           |Character|            |
// |                                  |
// |                                  |
// |                                  |
// |                                  |
// |                                  |
// |                                  |
// |                                  |
// |previous      stop          next  |
// |              end                 |
//  ==================================



import UIKit

protocol WorkoutDelegate: WorkoutViewController {
  func updateTimer(time: String, remainingTime: String, elapsedTime: String)
  func updateStartStopButton(isPaused: Bool)
  func updateExerciseLabel(text: String)
}

class WorkoutViewController:OutrunViewController {
  
  var workout:WorkoutModel?
  
  var handler:WorkoutHandler?
  
  var containerView = OutrunStackView()
  
  var timerStackView = OutrunStackView()
  var elapsedTimerLabel = OutrunLabel()
  var splitTimerLabel = OutrunLabel()
  var remainingTimerLabel = OutrunLabel()

  var workoutView = UIImageView()
  var exerciseTitleLabel = OutrunLabel()

  var controlStackView = OutrunStackView()
  var previousExerciseButton = UIButton()
  var startEndStackView = OutrunStackView()
  var startStopButton = UIButton()
  var endButton = UIButton()
  var nextExerciseButton = UIButton()

  
  override func viewDidLoad() {
    super.viewDidLoad()
        
    guard let workout = workout else {
      fatalError("You must pass a workout to show this view controller")
    }
    
    self.hideBackButton()

    
    handler = WorkoutHandler(workout: workout, delegate: self)
    title = handler?.workout.name
    navigationItem.largeTitleDisplayMode = .never

    setupViews()
    self.handler?.updateTimer()
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
    controlStackView.addArrangedSubview(previousExerciseButton)
    controlStackView.addArrangedSubview(startEndStackView)
    controlStackView.addArrangedSubview(nextExerciseButton)
    controlStackView.alignment = .center
    controlStackView.distribution = .equalSpacing
    controlStackView.axis = .horizontal
    controlStackView.spacing = CGFloat(20.0)
    
    startEndStackView.addArrangedSubview(startStopButton)
    startEndStackView.addArrangedSubview(endButton)
    startEndStackView.alignment = .center
    startEndStackView.distribution = .equalSpacing
    startEndStackView.axis = .vertical
    startEndStackView.spacing = CGFloat(20.0)
    
    // previousButton
    previousExerciseButton.setAttributedTitle(
      NSAttributedString(
        string: "<",
        attributes: [
          .foregroundColor: UIColor.OutrunLaserBlue,
          .font : UIFont(name: "Pixel-01", size: 40) ?? UIFont.systemFont(ofSize: 18)
        ]
      ),
      for: .normal
    )
    previousExerciseButton.addTarget(self, action: #selector(self.previousExerciseButtonTapped), for: .touchUpInside)
    previousExerciseButton.layer.cornerRadius = 3
    previousExerciseButton.titleEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    previousExerciseButton.backgroundColor = UIColor.darkGray
    
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

    // endButton
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
    
    
    // nextbutton
    nextExerciseButton.setAttributedTitle(
      NSAttributedString(
        string: ">",
        attributes: [
          .foregroundColor: UIColor.OutrunLaserBlue,
          .font : UIFont(name: "Pixel-01", size: 40) ?? UIFont.systemFont(ofSize: 18)
        ]
      ),
      for: .normal
    )
    nextExerciseButton.addTarget(self, action: #selector(self.nextExerciseButtonTapped), for: .touchUpInside)
    nextExerciseButton.layer.cornerRadius = 3
    nextExerciseButton.titleEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    nextExerciseButton.backgroundColor = UIColor.darkGray
    
    NSLayoutConstraint.activate([
      containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      containerView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
      containerView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
      
      timerStackView.rightAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.rightAnchor, constant: -8),
      
      startStopButton.widthAnchor.constraint(equalToConstant: 140),
      startStopButton.heightAnchor.constraint(equalToConstant: 80),
      
      endButton.widthAnchor.constraint(equalToConstant: 70),
      endButton.heightAnchor.constraint(equalToConstant: 40)
    ])
  }
  
  func setTimerText(label: OutrunLabel, time: String) {
    label.text = time
  }
  
  @objc func playPauseButtonTapped() {
    handler?.playPauseTapped()
  }
  
  @objc func endButtonTapped() {
    handler?.playPauseTapped()
    
    let alertController = UIAlertController(
      title: "Are you Sure?",
      message: "Leaving in the middle of a workout will cause you to lose all progress.",
      preferredStyle: .alert
    )
    alertController.addAction(
      UIAlertAction(
        title: NSLocalizedString("OK", comment: "Default action"),
        style: .default,
        handler: { [unowned self] _ in
          self.handler?.handleEnd()
          self.navigationController?.popToRootViewController(animated: true)
      })
    )
    alertController.addAction(
      UIAlertAction(
        title: NSLocalizedString("Cancel", comment: "Cancel Action"),
        style: .default,
        handler: { [unowned self] _ in
          self.handler?.playPauseTapped()
        }
      )
    )
    self.present(alertController, animated: true, completion: nil)
  }
  
  @objc func previousExerciseButtonTapped() {
    handler?.previousExercise()
  }
  
  @objc func nextExerciseButtonTapped() {
    handler?.nextExercise()
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
    self.setTimerText(label: self.elapsedTimerLabel, time: elapsedTime)
    self.setTimerText(label: self.splitTimerLabel, time: time)
    self.setTimerText(label: self.remainingTimerLabel, time: remainingTime)
  }
  
  
}
