//
//  Workout.swift
//  CodeDump
//
//  Created by Luke Solomon on 5/5/20.
//  Copyright © 2020 Observatory. All rights reserved.
//

import UIKit

enum WorkoutType:String {
  case HIIT = "HIIT"
  case Run = "Run"
  case Yoga = "Yoga"
  case Strength = "Strength"
  case Custom = "Custom"
}

struct Workout {
  
  var name:String
  var type:WorkoutType
  var length:Int // represented in minutes
  var warmupLength:Int // represented in seconds
  var intervalLength:Int
  var restLength:Int
  var numberOfIntervals:Int
  var numberOfSets:Int
  var exercises:[Exercise]
 
//  init(_ name:String,_ type:WorkoutType, _ length:Int) {
//    self.name = name
//    self.type = type
//    self.length = length
//  }

}

struct Exercise {
  var name:String
  var image:UIImage
}
