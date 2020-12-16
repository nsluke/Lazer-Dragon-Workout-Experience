//
// Created by Luke Solomon
// Copyright (c) 2020 Luke Solomon. All rights reserved.
//

import Foundation

// MARK: - Workout Segment
enum WorkoutSegment:Int {
  case Stopped = 0
  case Warmup = 1
  case Interval = 2
  case Rest = 3
  case RestBetweenSets = 4
  case Cooldown = 5
  case End = 6
}

class WorkoutSceneLocalDataManager {
  
  // LOCALDATAMANAGER -> INTERACTOR
  weak var interactor:WorkoutSceneInteractor?
  
  var workout:WorkoutModel?
  
  var splitTime:Int?
  var elapsedTime:Int = 0
  var remainingTime:Int?
  
  
  var isPlaying = false
  var workoutState = WorkoutSegment.Stopped
  var exercises:[ExerciseModel]!
  var currentExercise:Int = 0
  lazy var intervalsRemaining:Int = { return workout!.numberOfIntervals }()
  lazy var setsRemaining:Int = { return workout!.numberOfSets }()
  
  func updateSplits(i:Int) {
    if splitTime! < i {
      splitTime = 0
    } else {
      splitTime! -= i
    }
    
    if remainingTime! < i {
      remainingTime = 0
    } else {
      remainingTime! -= 1
    }
    
    elapsedTime += i
  }
  

  
}

// INTERACTOR -> LOCALDATAMANAGER
extension WorkoutSceneLocalDataManager:WorkoutSceneLocalDataManagerInputProtocol {

  func tick() {
    print("Timer executing")
    print("")
    print("split:" + String.timeToFormattedString(time: self.splitTime!))
    print("")
    print("remaining:" + String.timeToFormattedString(time: self.remainingTime!))
    print("")
    print("elapsed:" + String.timeToFormattedString(time: self.elapsedTime))
    
    self.updateSplits(i:1)
    interactor?.onTick(remainingTime: remainingTime!)
  }
  
  func willTransitionToNext() {
    intervalsRemaining -= 1
    currentExercise += 1
    if intervalsRemaining < 0 {
      intervalsRemaining = 0
      currentExercise = 0
      setsRemaining -= 1
      if setsRemaining < 0 {
        setsRemaining = 0
        interactor?.handleShouldCooldown(length: workout!.cooldownLength)
      } else {
        interactor?.handleShouldRestBetweenSets(length: workout!.restBetweenSetLength)
      }
    } else {
      interactor?.handleShouldInterval(exercise: exercises[currentExercise])
    }
  }
  
  func willTransitionToPrevious() {
    intervalsRemaining += 1
    currentExercise -= 1
    if intervalsRemaining == workout?.numberOfIntervals {
      intervalsRemaining = 0
      currentExercise = 0
      setsRemaining += 1
      if setsRemaining == workout?.numberOfSets {
        setsRemaining = workout!.numberOfSets
        interactor?.handleShouldWarmup(warmupLength: workout!.warmupLength)
      } else {
        interactor?.handleShouldRestBetweenSets(length: workout!.restBetweenSetLength)
      }
    } else {
      interactor?.handleShouldInterval(exercise: exercises[currentExercise])
    }
  }
  
  func willStop() {
    workoutState = .Stopped
    
  }
  
  func willWarmup() {
    workoutState = .Warmup

  }
  
  func willInterval() {
    workoutState = .Interval

  }
  
  func willRest() {
    workoutState = .Rest

  }
  
  func willRestBetweenSets() {
    workoutState = .RestBetweenSets

  }
  
  func willCooldown() {
    workoutState = .Cooldown

  }
  
  func willEnd() {
    workoutState = .End

  }
  
  
  func fetchPreviousExercise() {
    interactor?.onPreviousExerciseFetched(exercise:exercises[currentExercise-1])
  }
  
  func fetchNextExercise() {
    currentExercise -= 1
    if currentExercise < 0 {
      currentExercise = 0
    }
    interactor?.onPreviousExerciseFetched(exercise:exercises[currentExercise+1])
  }
  
  func fetchIsPlaying() {
    interactor?.onFetchIsPlaying(isPlaying:isPlaying)
  }

}
