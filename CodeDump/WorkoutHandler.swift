//
//  WorkoutHandler.swift
//  CodeDump
//
//  Created by Luke Solomon on 5/28/20.
//  Copyright © 2020 Observatory. All rights reserved.
//
/*
import UIKit

class WorkoutHandler: NSObject {

  init(workout: WorkoutModel, delegate: WorkoutDelegate) {
    
    if workout.warmupLength == 0 {
      splitTime = workout.intervalLength
    } else {
      splitTime = workout.warmupLength
    }
    intervalsRemaining = workout.numberOfIntervals
    setsRemaining = workout.numberOfSets
    
    let intervalTotalLength = (workout.numberOfSets * workout.numberOfIntervals) * (workout.intervalLength + workout.restLength)
    let workoutLength = workout.warmupLength + intervalTotalLength + workout.intervalLength
    
    remainingTime = workoutLength
    
    super.init()
    workoutState = .Stopped
    self.handleStopped()
  }
  
  func playPauseTapped() {

  }

  func updateTimer() {

  }
  
  func updateSplits(_ i: Int) {

  }
  
  func handleTimerEnded() {

 }
  
  func previousExercise() {
    debugState()
    if isPlaying {
      playPauseTapped()
    }
    if workoutState != .Warmup {
      updateSplits(-workout.intervalLength)
      
      intervalsRemaining += 1
      if intervalsRemaining == workout.numberOfIntervals {
        setsRemaining += 1
        if setsRemaining == workout.numberOfSets {
          handleWarmup()
        } else {
          handleRestBetweenSets()
        }
      } else {
        handleInterval()
      }
    }
  }
  
  func nextExercise() {
    if isPlaying {
      playPauseTapped()
    }
    
    updateSplits(workout.intervalLength)
    handleNextExercise()
  }
  
  func handleNextExercise() {
    debugState()
    intervalsRemaining -= 1
    if intervalsRemaining < 0 {
      intervalsRemaining = 0
      setsRemaining -= 1
      if setsRemaining < 0 {
        handleCooldown()
      } else {
        handleRestBetweenSets()
      }
    } else {
      handleInterval()
    }
  }
  
  func handleStopped() {
    if workout.warmupLength == 0 {
      workoutState = .Interval
      workoutDelegate?.updateExerciseLabel(text: "Interval")
      splitTime = workout.intervalLength
    } else {
      workoutState = .Warmup
      workoutDelegate?.updateExerciseLabel(text: "Warmup")
      splitTime = workout.warmupLength
    }
  }
  
  func handlePause() {
    workoutState = .Paused
    workoutDelegate?.updateExerciseLabel(text: "Paused")
  }
  
  func handleWarmup() {
    workoutState = .Warmup
    workoutDelegate?.updateExerciseLabel(text: "Warmup")
    splitTime = workout.warmupLength
    startTimer()
  }
  
  func handleInterval() {
    workoutState = .Interval
    
    let exerciseIndex = max(0, min(workout.exercises.count - 1, intervalsRemaining))
    var exerciseLabelText = "\(workout.exercises[exerciseIndex].name)"
    if workout.exercises[exerciseIndex].reps > 0 {
      exerciseLabelText.append("x \(workout.exercises[exerciseIndex].reps)")
    }
    
    workoutDelegate?.updateExerciseLabel(text: exerciseLabelText)
    splitTime = workout.intervalLength
    
//    startTimer()
  }
  
  func handleRest() {
    workoutState = .Rest
    workoutDelegate?.updateExerciseLabel(text: "Rest")
    splitTime = workout.restLength
//    startTimer()
  }
  
  func handleRestBetweenSets() {
    workoutState = .RestBetweenSets
    workoutDelegate?.updateExerciseLabel(text: "Rest")
    splitTime = workout.restLength
//    startTimer()
  }
  
  func handleCooldown() {
    workoutDelegate?.updateExerciseLabel(text: "Cooldown")
    workoutState = .Cooldown
    splitTime = workout.cooldownLength
//    startTimer()
  }
  
  func handleEnd() {
    workoutDelegate?.updateExerciseLabel(text: "Workout Complete")
    workoutState = .End
  }
  
  func endWorkout() {
    stopTimer()
    workoutState = .End
  }
  
  func debugState() {
    print(splitTime, elapsedTime, remainingTime, isPlaying, workoutState, intervalsRemaining, setsRemaining)
  }
  
}

/*
 var timer : Repeater?
 
 var timerQueue = DispatchQueue.init(
   label: "workoutTimer",
   qos: .userInteractive,
   attributes: .initiallyInactive,
   autoreleaseFrequency: .inherit,
   target: .main
 )
 
 var splitTime:Int
 
 var elapsedTime:Int = 0
 var remainingTime:Int
 
 var isPlaying = false
 var workoutState = WorkoutSegment.Stopped
 
 var intervalsRemaining:Int
 var setsRemaining:Int
 */
*/
