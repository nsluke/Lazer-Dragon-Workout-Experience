//
//  Workout.swift
//  CodeDump
//
//  Created by Luke Solomon on 5/5/20.
//  Copyright © 2020 Observatory. All rights reserved.
//

import UIKit
import CoreData

enum WorkoutType:String {
  case HIIT = "HIIT"
  case Run = "Run"
  case Yoga = "Yoga"
  case Strength = "Strength"
  case Custom = "Custom"
}

class WorkoutModel {

  var name:String
  var type:WorkoutType
  var length:Int // represented in minutes

  var warmupLength:Int // represented in seconds
  var intervalLength:Int
  var restLength:Int

  var numberOfIntervals:Int
  var numberOfSets:Int
  var restBetweenSetLength:Int
  var cooldownLength:Int
  var exercises:[ExerciseModel]

  init(
    name:String,
    type:WorkoutType,
    length:Int,

    warmupLength:Int,
    intervalLength:Int,
    restLength:Int,

    numberOfIntervals:Int,
    numberOfSets:Int,
    restBetweenSetLength:Int,
    cooldownLength:Int,
    exercises:[ExerciseModel]
    ) {

    self.name = name
    self.type = type
    self.length = length

    self.warmupLength = warmupLength
    self.intervalLength = intervalLength
    self.restLength = restLength

    self.numberOfIntervals = numberOfIntervals
    self.numberOfSets = numberOfSets
    self.restBetweenSetLength = restBetweenSetLength
    
    self.cooldownLength = cooldownLength
    
    self.exercises = exercises
  }

}
extension WorkoutModel: Equatable {
  static func == (lhs: WorkoutModel, rhs: WorkoutModel) -> Bool {
    if lhs.name == rhs.name
    && lhs.type == rhs.type
    && lhs.length == rhs.length
        
    && lhs.warmupLength == rhs.warmupLength
    && lhs.intervalLength == rhs.intervalLength
    && lhs.restLength == rhs.restLength
        
    && lhs.numberOfIntervals == rhs.numberOfIntervals
    && lhs.numberOfSets == rhs.numberOfSets
    && lhs.restBetweenSetLength == rhs.restBetweenSetLength
        
    && lhs.cooldownLength == rhs.cooldownLength
    
    && lhs.exercises == rhs.exercises
    {
      return true
    } else {
      return false
    }
  }
}


struct ExerciseModel {
  var order:Int
  var name:String
  var image:UIImage
  var splitLength:Int
  var reps:Int
}
extension ExerciseModel: Equatable {
  static func == (lhs: ExerciseModel, rhs: ExerciseModel) -> Bool {
    if lhs.order == rhs.order
    && lhs.name == rhs.name
    && lhs.image == rhs.image
    && lhs.splitLength == rhs.splitLength
    && lhs.reps == rhs.reps
    {
      return true
    } else {
      return false
    }
  }
}
