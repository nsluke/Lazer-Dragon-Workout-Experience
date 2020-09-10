//
//  WorkoutHandler.swift
//  CodeDump
//
//  Created by Luke Solomon on 5/28/20.
//  Copyright © 2020 Observatory. All rights reserved.
//

import UIKit
import Repeat

enum WorkoutSegment:Int {
  case Stopped = 0
  case Paused = 1
  case Warmup = 2
  case Interval = 3
  case Rest = 4
  case RestBetweenSets = 5
  case Cooldown = 6
  case End = 7
}

class WorkoutHandler: NSObject {
  
  var workout:WorkoutModel
  weak var workoutDelegate:WorkoutDelegate?
  
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
  
  
  init(workout: WorkoutModel, delegate: WorkoutDelegate) {
    self.workout = workout
    self.workoutDelegate = delegate
    
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
    if isPlaying {
      stopTimer()
    } else {
      startTimer()
    }
    
    isPlaying = !isPlaying
    workoutDelegate?.updateStartStopButton(isPaused: isPlaying)
  }
  
  func startTimer() {
    if self.timer == nil {
      self.timer = Repeater(
        interval: .seconds(1),
        mode: .infinite) { timer in
          print("timer executing")
          print("")
          print("split:")
          let formattedSplitTime = String.timeToFormattedString(time: self.splitTime)
          print("")
          print("remaining:")
          let formattedRemainingTime = String.timeToFormattedString(time: self.remainingTime)
          print("")
          print("elapsed:")
          let formattedElapsedTime = String.timeToFormattedString(time: self.elapsedTime)
          
          DispatchQueue.main.async {
            self.workoutDelegate?.updateTimer(time: formattedSplitTime, remainingTime: formattedRemainingTime, elapsedTime: formattedElapsedTime)
          }
          
          self.updateSplits(1)
      }
    }
    self.timer!.start()
  }
  
  func stopTimer() {
    timer?.pause()
  }
  
  func updateTimer() {
    print("")
    print("split:")
    let formattedSplitTime = String.timeToFormattedString(time: splitTime)
    print("")
    print("remaining:")
    let formattedRemainingTime = String.timeToFormattedString(time: remainingTime)
    print("")
    print("elapsed:")
    let formattedElapsedTime = String.timeToFormattedString(time: elapsedTime)
    
    self.workoutDelegate?.updateTimer(time: formattedSplitTime, remainingTime: formattedRemainingTime, elapsedTime: formattedElapsedTime)
    
    updateSplits(1)
  }
  
  func updateSplits(_ i: Int) {
    if splitTime < i {
      splitTime = 0
      handleTimerEnded()
    } else {
      splitTime -= i
    }
    
    if remainingTime < i {
      remainingTime = 0
    } else {
      remainingTime -= 1
    }
    
    elapsedTime += i
  }
  
  func handleTimerEnded() {
    stopTimer()
    
    switch workoutState {
    case .Stopped:
      if workout.warmupLength == 0 {
        workoutState = .Interval
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
      handleNextExercise()
      break
      
    case .RestBetweenSets:
      handleInterval()
      break
      
    case .Cooldown:
      handleEnd()
      break
      
    case .Paused:
      break
      
    case .End:
      break
    }
  }
  
  func previousExercise() {
    playPauseTapped()
    updateSplits(workout.intervalLength)
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
  
  func nextExercise() {
    playPauseTapped()
    updateSplits(workout.intervalLength)
    handleNextExercise()
  }
  
  func handleNextExercise() {
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
    workoutDelegate?.updateExerciseLabel(text: workout.exercises[intervalsRemaining].name)
    splitTime = workout.intervalLength
    startTimer()
  }
  
  func handleRest() {
    workoutState = .Rest
    workoutDelegate?.updateExerciseLabel(text: "Rest")
    splitTime = workout.restLength
    startTimer()
  }
  
  func handleRestBetweenSets() {
    workoutState = .RestBetweenSets
    workoutDelegate?.updateExerciseLabel(text: "Rest")
    splitTime = workout.restLength
    startTimer()
  }
  
  func handleCooldown() {
    workoutDelegate?.updateExerciseLabel(text: "Cooldown")
    workoutState = .Cooldown
    splitTime = workout.cooldownLength
    startTimer()
  }
  
  func handleEnd() {
    workoutDelegate?.updateExerciseLabel(text: "Workout Complete")
    workoutState = .End
  }
  
  func endWorkout() {
    stopTimer()
    workoutState = .End
  }
  
}
