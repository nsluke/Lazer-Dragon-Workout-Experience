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
//  var exercises:[Exercise]

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
    cooldownLength:Int
//    _ exercises:[Exercise]
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
//    self.exercises = exercises
  }

//  init(workout: NSManagedObject) {
//    self.name = workout.value(forKeyPath: "name") as! String
//    self.type = workout.value(forKeyPath: "type") as! WorkoutType // add handling to convert from string to workoutType
//    self.length = workout.value(forKeyPath: "length") as! Int
//
//    self.warmupLength = workout.value(forKeyPath: "warmupLength") as! Int
//    self.intervalLength = workout.value(forKeyPath: "intervalLength") as! Int
//    self.restLength = workout.value(forKeyPath: "restLength") as! Int
//
//    self.numberOfIntervals = workout.value(forKeyPath: "numberOfIntervals") as! Int
//    self.numberOfSets = workout.value(forKeyPath: "numberOfSets") as! Int
//    self.exercises = workout.value(forKeyPath: "exercises") as! [Exercise]
//  }

}

//struct ExerciseModel {
//  var name:String
//  var image:UIImage
//}
