//
// Created by Luke Solomon
// Copyright (c) 2020 Luke Solomon. All rights reserved.
//

import Foundation
import Repeat

class WorkoutSceneInteractor {
  // INTERACTOR -> PRESENTER
  weak var presenter: WorkoutSceneInteractorOutputProtocol?
  // INTERACTOR -> LOCALDATAMANAGER
  var localDatamanager: WorkoutSceneLocalDataManagerInputProtocol?
  
  var timer:Repeater?
  var timerQueue:DispatchQueue?
  
  func startTimer() {
    if timer == nil {
      timer = Repeater(interval: .seconds(1), mode: .infinite) { [weak self] _ in
        self?.tick()
      }
    }
    timer?.start()
  }
  
  func stopTimer() {
    timer?.pause()
  }
  
  func tick() {
    localDatamanager?.tick()
  }

  func handleTimerEnded() {
    pauseWorkout()
    switch localDatamanager?.workoutState {
    case .Stopped:
      if localDatamanager?.workout?.warmupLength == 0 {
        localDatamanager?.workoutState = .Interval
        handleInterval()
      } else {
        handleWarmup()
      }
      break
      
    case .Warmup:
      handleInterval()
      break
      
    case .Interval:
      handleRest()
      break
      
    case .Rest:
      handleNext()
      break
      
    case .RestBetweenSets:
      handleInterval()
      break
      
    case .Cooldown:
      handleEnd()
      break
      
    case .End:
      handleEnd()
      break
      
    case .none:
      break
    }
  }
  
  func handleStop() {
    localDatamanager?.willStop()
    stopTimer()
    presenter?.updateExerciseLabel(text: "")
  }
  
  func handleWarmup() {
    localDatamanager?.willWarmup()
    presenter?.updateExerciseLabel(text: "Warmup")
  }
  
  func handleInterval() {
    
  }
  
  func handleRest() {
    
  }
  
  func handleRestBetweenSets() {
    
  }
  
  func handleCooldown() {
    
  }
  
  func handleEnd() {
    endWorkout()
  }
  
  func handleNext() {
    localDatamanager?.fetchNextExercise()
  
  }
  
  func handlePrevious() {
    localDatamanager?.fetchPreviousExercise()
  }

}

// PRESENTER -> INTERACTOR
extension WorkoutSceneInteractor:WorkoutSceneInteractorInputProtocol {
  func playPauseToggle() {
    localDatamanager?.fetchIsPlaying()
  }
  
  func pauseWorkout() {
    stopTimer()
    presenter?.handlePause()
  }
  
  func resumeWorkout() {
    startTimer()
    presenter?.handleResume()
  }
  
  func endWorkout() {
    pauseWorkout()
    presenter?.handleEndWorkout()
  }
  
  func previousExercise() {
    pauseWorkout()
    
    localDatamanager?.willTransitionToPrevious()
  }
  
  func nextExercise() {
    pauseWorkout()

    localDatamanager?.willTransitionToPrevious()
  }
}

// LOCALDATAMANAGER -> INTERACTOR
extension WorkoutSceneInteractor:WorkoutSceneLocalDataManagerOutputProtocol {
  
  func onPreviousExerciseFetched(exercise: ExerciseModel) {
    presenter?.handlePreviousExercise(exercise: exercise)
  }
  
  func onNextExerciseFetched(exercise: ExerciseModel) {
    presenter?.handleNextExercise(exercise: exercise)
  }
  
  func onFetchIsPlaying(isPlaying:Bool) {
    isPlaying ? pauseWorkout() : resumeWorkout()
  }

  func onTick(remainingTime:Int) {
    if remainingTime == 0 {
      handleTimerEnded()
    }
  }
  
  func handleShouldStop() {
    handleStop()
  }
  
  func handleShouldWarmup(warmupLength:Int) {
    handleWarmup()
  }
  
  func handleShouldInterval(exercise:ExerciseModel) {
    handleInterval()
  }
  
  func handleShouldRest(length:Int) {
    handleRest()
  }
  
  func handleShouldRestBetweenSets(length:Int) {
    handleRestBetweenSets()
  }
  
  func handleShouldCooldown(length:Int) {
    handleCooldown()
  }
  
  func handleShouldEnd() {
    handleEnd()
  }
}
