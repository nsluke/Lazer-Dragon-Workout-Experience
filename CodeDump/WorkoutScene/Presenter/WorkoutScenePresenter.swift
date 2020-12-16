//
// Created by Luke Solomon
// Copyright (c) 2020 Luke Solomon. All rights reserved.
//

import Foundation

class WorkoutScenePresenter {
  // PRESENTER -> VIEW
  weak var view: WorkoutSceneViewProtocol?
  // PRESENTER -> INTERACTOR
  var interactor: WorkoutSceneInteractorInputProtocol?
  // PRESENTER -> ROUTER
  var router: WorkoutSceneRouterProtocol?
}

// VIEW -> PRESENTER
extension WorkoutScenePresenter: WorkoutScenePresenterProtocol {
  func pauseWorkout() {
    interactor?.pauseWorkout()
  }
  
  func resumeWorkout() {
    interactor?.resumeWorkout()
  }
  
  func playPauseButtonTapped() {
    interactor?.playPauseToggle()
  }
  
  func endButtonTapped() {
    interactor?.endWorkout()
  }
  
  func previousExerciseButtonTapped() {
    interactor?.previousExercise()
  }
  
  func nextExerciseButtonTapped() {
    interactor?.nextExercise()
  }
}
// INTERACTOR -> PRESENTER
extension WorkoutScenePresenter: WorkoutSceneInteractorOutputProtocol {

  func handleResume() {
    updateStartStopButton(text: "Continue")
  }
  
  func handlePause() {
    updateStartStopButton(text: "Paused")
  }
  
  func handleEndWorkout() {
    router?.handleEndWorkout(fromView: view!)
  }
  
  func handlePreviousExercise(exercise: ExerciseModel) {
    updateExerciseLabel(text: exercise.name)
  }
  
  func handleNextExercise(exercise: ExerciseModel) {
    updateExerciseLabel(text: exercise.name)
  }

  func updateTimer(time: String, remainingTime: String, elapsedTime: String) {
    DispatchQueue.main.async { [weak self] in
      self?.view?.updateTimer(time: time, remainingTime: remainingTime, elapsedTime: elapsedTime)
    }
  }
  
  func updateStartStopButton(text: String) {
    DispatchQueue.main.async { [weak self] in
      self?.view?.updateStartStopButton(text: text)
    }
  }
  
  func updateExerciseLabel(text: String) {
    DispatchQueue.main.async { [weak self] in
      self?.view?.updateExerciseLabel(text: text)
    }
  }
  
}
