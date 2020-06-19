//
//  WorkoutHandler.swift
//  CodeDump
//
//  Created by Luke Solomon on 5/28/20.
//  Copyright © 2020 Observatory. All rights reserved.
//

import UIKit

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
  weak var workoutDelegate:WorkoutDelegate!
  
  var remainingTimer = Timer()
  var timer = Timer()
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
    workoutDelegate.updateStartStopButton(isPaused: isPlaying)
  }
  
  
  func startTimer() {
    timer = Timer.scheduledTimer(
      timeInterval: 1,
      target: self,
      selector: #selector(updateTimer),
      userInfo: nil,
      repeats: true)
  }
  
  func stopTimer() {
    timer.invalidate()
    remainingTimer.invalidate()
  }
    
  @objc func updateTimer() {
    print("")
    print("split:")
    let formattedSplitTime = timeToFormattedString(time: splitTime)
    print("")
    print("remaining:")
    let formattedRemainingTime = timeToFormattedString(time: remainingTime)
    print("")
    print("elapsed:")
    let formattedElapsedTime = timeToFormattedString(time: elapsedTime)
    
    workoutDelegate.updateTimer(time: formattedSplitTime, remainingTime: formattedRemainingTime, elapsedTime: formattedElapsedTime)
    
    if splitTime < 1 {
      splitTime = 0
      handleTimerEnded()
    } else {
      splitTime -= 1
    }
    
    if remainingTime < 1 {
      remainingTime = 0
    } else {
      remainingTime -= 1
    }
    
    elapsedTime += 1
  }
  
  func timeToFormattedString(time:Int) -> String {
    let time = time
    
    // TODO: put new timer logic here
    let hours = time/3600
    
    var minutes = time / 60
    
    var seconds = time % 60
    
    
    if hours > 1 {
      minutes = (time % (60 * 60)) / 60
    }
    
    if minutes > 1 {
      seconds = time % 60
    }
    
    var formattedTimeString = ""
    
    if hours < 1 {
      formattedTimeString = String(format: "%2i:%02i", minutes, seconds)
    } else {
      formattedTimeString = String(format: "%2i:%02i:%02i", hours, minutes, seconds)
    }
    
    print("time: \(time)")
    print("hours: \(hours)")
    print("minutes: \(minutes)")
    print("seconds: \(seconds)")
    print("formattedTimeString: \(formattedTimeString)")
    
    return formattedTimeString
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
      intervalsRemaining -= 1
      if intervalsRemaining < 0 {
        setsRemaining -= 1
        if setsRemaining < 0 {
          handleCooldown()
        } else {
          handleRestBetweenSets()
        }
      } else {
        handleInterval()
      }
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
  
  func handleStopped() {

    if workout.warmupLength == 0 {
      workoutState = .Interval
      workoutDelegate.updateExerciseLabel(text: "Interval")
      splitTime = workout.intervalLength
    } else {
      workoutState = .Warmup
      workoutDelegate.updateExerciseLabel(text: "Warmup")
      splitTime = workout.warmupLength
    }
  }
    
  func handlePause() {
    workoutState = .Paused
    workoutDelegate.updateExerciseLabel(text: "Paused")
  }

  func handleWarmup() {
    workoutState = .Warmup
    workoutDelegate.updateExerciseLabel(text: "Warmup")
    splitTime = workout.warmupLength
    startTimer()
  }
  
  func handleInterval() {
    workoutState = .Interval
    workoutDelegate.updateExerciseLabel(text: "Interval (exercise coming soon)")
    splitTime = workout.intervalLength
    startTimer()
  }
  
  func handleRest() {
    workoutState = .Rest
    workoutDelegate.updateExerciseLabel(text: "Rest")
    splitTime = workout.restLength
    startTimer()
  }
  
  func handleRestBetweenSets() {
    workoutState = .RestBetweenSets
    workoutDelegate.updateExerciseLabel(text: "Rest")
    splitTime = workout.restLength
    startTimer()
  }
  
  func handleCooldown() {
    workoutDelegate.updateExerciseLabel(text: "Cooldown")
    workoutState = .Cooldown
    splitTime = workout.cooldownLength
    startTimer()
  }
  
  func handleEnd() {
    workoutDelegate.updateExerciseLabel(text: "Workout Complete")
    workoutState = .End
  }
  
  
}
