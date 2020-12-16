//
// Created by Luke Solomon
// Copyright (c) 2020 Luke Solomon. All rights reserved.
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


import Foundation
import UIKit

class WorkoutSceneView: OutrunViewController {
  // VIEW -> PRESENTER
  var presenter: WorkoutScenePresenterProtocol?
      
  // MARK: - Interface
  lazy var containerView:OutrunStackView = {
    let stackView = OutrunStackView()
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = .vertical
    stackView.backgroundColor = UIColor.OutrunDarkerGray
    stackView.distribution = .fillProportionally
    stackView.alignment = .center
    stackView.addArrangedSubview(timerStackView)
    stackView.addArrangedSubview(workoutView)
    stackView.addArrangedSubview(exerciseTitleLabel)
    stackView.addArrangedSubview(controlStackView)
    return stackView
  }()
  
  lazy var timerStackView:OutrunStackView = {
    let stackView = OutrunStackView()
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.alignment = .center
    stackView.distribution = .equalSpacing
    stackView.axis = .horizontal
    stackView.addArrangedSubview(elapsedTimerLabel)
    stackView.addArrangedSubview(splitTimerLabel)
    stackView.addArrangedSubview(remainingTimerLabel)
    return stackView
  }()
  
  lazy var elapsedTimerLabel:OutrunLabel = {
    let label = OutrunLabel()
    label.font = UIFont(name: "Pixel-01", size: 20) ?? UIFont.systemFont(ofSize: 30)
    label.textColor = UIColor.OutrunLaserGreen
    return label
  }()
  
  lazy var splitTimerLabel:OutrunLabel = {
    let label = OutrunLabel()
    label.font = UIFont(name: "Pixel-01", size: 70) ?? UIFont.systemFont(ofSize: 30)
    label.textColor = UIColor.OutrunPaleYellow
    return label
  }()
  
  lazy var remainingTimerLabel:OutrunLabel = {
    let label = OutrunLabel()
    label.font = UIFont(name: "Pixel-01", size: 20) ?? UIFont.systemFont(ofSize: 30)
    label.textColor = UIColor.OutrunSoftRed
    return label
  }()
  
  lazy var workoutView:UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    return imageView
  }()
  
  lazy var exerciseTitleLabel:OutrunLabel = {
    let label = OutrunLabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont(name: "Pixel-01", size: 30) ?? UIFont.systemFont(ofSize: 30)
    label.textColor = UIColor.OutrunPaleYellow
    return label
  }()
  
  lazy var controlStackView:OutrunStackView = {
    let stackView = OutrunStackView()
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.alignment = .center
    stackView.distribution = .equalSpacing
    stackView.axis = .horizontal
    stackView.spacing = CGFloat(20.0)
    stackView.addArrangedSubview(previousExerciseButton)
    stackView.addArrangedSubview(startEndStackView)
    stackView.addArrangedSubview(nextExerciseButton)
    return stackView
  }()
  
  lazy var previousExerciseButton:OutrunButton = {
    let outrunButton = OutrunButton()
    outrunButton.setAttributedTitle(
      NSAttributedString(
        string: "<",
        attributes: [
          .foregroundColor: UIColor.OutrunLaserBlue,
          .font : UIFont(name: "Pixel-01", size: 40) ?? UIFont.systemFont(ofSize: 18)
        ]
      ),
      for: .normal
    )
    outrunButton.addTarget(self, action: #selector(self.previousExerciseButtonTapped), for: .touchUpInside)
    outrunButton.layer.cornerRadius = 3
    outrunButton.titleEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    outrunButton.backgroundColor = UIColor.darkGray
    return outrunButton
  }()
  
  lazy var startEndStackView:OutrunStackView = {
    let stackView = OutrunStackView()
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.alignment = .center
    stackView.distribution = .equalSpacing
    stackView.axis = .vertical
    stackView.spacing = CGFloat(20.0)
    stackView.addArrangedSubview(startStopButton)
    stackView.addArrangedSubview(endButton)
    return stackView
  }()
  
  var startStopButton:OutrunButton = {
    let outrunButton = OutrunButton()
    outrunButton.setAttributedTitle(
      NSAttributedString(
        string: "Start",
        attributes: [
          .foregroundColor: UIColor.OutrunLaserBlue,
          .font : UIFont(name: "Pixel-01", size: 40) ?? UIFont.systemFont(ofSize: 18)
        ]
      ),
      for: .normal
    )
    outrunButton.addTarget(self, action: #selector(playPauseButtonTapped), for: .touchUpInside)
    outrunButton.layer.cornerRadius = 3
    outrunButton.titleEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    outrunButton.backgroundColor = UIColor.darkGray
    return outrunButton
  }()
  
  var endButton:OutrunButton = {
    let outrunButton = OutrunButton()
    outrunButton.setAttributedTitle(
      NSAttributedString(
        string: "End",
        attributes: [
          .foregroundColor: UIColor.OutrunLaserBlue,
          .font : UIFont(name: "Pixel-01", size: 30) ?? UIFont.systemFont(ofSize: 18)
        ]
      ),
      for: .normal
    )
    outrunButton.addTarget(self, action: #selector(endButtonTapped), for: .touchUpInside)
    outrunButton.layer.cornerRadius = 3
    outrunButton.titleEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
    outrunButton.backgroundColor = UIColor.darkGray
    return outrunButton
  }()
  
  var nextExerciseButton:OutrunButton = {
    let outrunButton = OutrunButton()
    outrunButton.setAttributedTitle(
      NSAttributedString(
        string: ">",
        attributes: [
          .foregroundColor: UIColor.OutrunLaserBlue,
          .font : UIFont(name: "Pixel-01", size: 40) ?? UIFont.systemFont(ofSize: 18)
        ]
      ),
      for: .normal
    )
    outrunButton.addTarget(self, action: #selector(nextExerciseButtonTapped), for: .touchUpInside)
    outrunButton.layer.cornerRadius = 3
    outrunButton.titleEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    outrunButton.backgroundColor = UIColor.darkGray
    return outrunButton
  }()
  
  // MARK: - View LifeCycle
  override func viewDidLoad() {
    super.viewDidLoad()

    setupViews()
  }
  
  func setupViews() {
    super.hideBackButton()

//    title = workout?.name
    navigationItem.largeTitleDisplayMode = .never
    navigationController?.navigationBar.backgroundColor = UIColor.OutrunDarkGray

    // Container View
    view.addSubview(containerView)
    view.backgroundColor = UIColor.OutrunDarkerGray

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
  
  // MARK: - Tap Selector Handling
  @objc func playPauseButtonTapped() {
    presenter?.playPauseButtonTapped()
  }
  
  @objc func endButtonTapped() {
    presenter?.pauseWorkout()
    
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
          self.presenter?.endButtonTapped()

      })
    )
    alertController.addAction(
      UIAlertAction(
        title: NSLocalizedString("Cancel", comment: "Cancel Action"),
        style: .default,
        handler: { [unowned self] _ in
          self.presenter?.resumeWorkout()
        }
      )
    )
    self.present(alertController, animated: true, completion: nil)
  }
  
  @objc func previousExerciseButtonTapped() {
    self.presenter?.previousExerciseButtonTapped()
  }
  
  @objc func nextExerciseButtonTapped() {
    self.presenter?.nextExerciseButtonTapped()
  }
  
  // MARK: - Other functions
  func setTimerText(label: OutrunLabel, time: String) {
    label.text = time
  }
  
  
}

// PRESENTER -> VIEW
extension WorkoutSceneView: WorkoutSceneViewProtocol {
  func updateTimer(time: String, remainingTime: String, elapsedTime: String) {
    self.setTimerText(label: self.elapsedTimerLabel, time: elapsedTime)
    self.setTimerText(label: self.splitTimerLabel, time: time)
    self.setTimerText(label: self.remainingTimerLabel, time: remainingTime)
  }
  
  func updateStartStopButton(text: String) {
    startStopButton.setAttributedTitle(
      NSAttributedString(
        string: text,
        attributes: [
          .foregroundColor: UIColor.OutrunLaserBlue,
          .font : UIFont(name: "Pixel-01", size: 40) ?? UIFont.systemFont(ofSize: 18)
        ]
      ),
      for: .normal
    )
  }
  
  func updateExerciseLabel(text: String) {
    exerciseTitleLabel.text = text
  }
}
