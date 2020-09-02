//
//  LaunchHandler.swift
//  CodeDump
//
//  Created by Luke Solomon on 7/4/20.
//  Copyright © 2020 Observatory. All rights reserved.
//

import Foundation
import UIKit

struct LaunchHandler {
  
  public static var shared = LaunchHandler()

  
  func launch() {
    initialDataCheck()
  }
  
  func initialDataCheck() {
    DataHandler.shared.getWorkouts(completion: { (result) in
      if case .success(let workouts) = result {
        print("initial data check successful: \(workouts)")
        if workouts.count == 0 {
          self.saveInitialWorkouts()
        }
      } else if case .failure = result {
        self.saveInitialWorkouts()
      }
    })
  }
    
  func saveInitialWorkouts() {
    let exercises = [
      ExerciseModel(order: 1, name: "Burpee", image: UIImage(), splitLength: 30),
      ExerciseModel(order: 2, name: "Situp", image: UIImage(), splitLength: 30),
      ExerciseModel(order: 3, name: "Pushup", image: UIImage(), splitLength: 30),
      ExerciseModel(order: 4, name: "Bicep Curl", image: UIImage(), splitLength: 30),
      ExerciseModel(order: 5, name: "Tricep extension", image: UIImage(), splitLength: 30),

      ExerciseModel(order: 6, name: "Lunge", image: UIImage(), splitLength: 30),
      ExerciseModel(order: 7, name: "Squat", image: UIImage(), splitLength: 30),
      ExerciseModel(order: 8, name: "Plank", image: UIImage(), splitLength: 30),
      ExerciseModel(order: 9, name: "Pull-up", image: UIImage(), splitLength: 30),
      ExerciseModel(order: 10, name: "Seated Back Row", image: UIImage(), splitLength: 30)
    ]
    
    let workoutModels = [
      WorkoutModel(name: "Neko", type: .Strength, length: 20, warmupLength: 500, intervalLength: 30, restLength: 30, numberOfIntervals: 10, numberOfSets: 2, restBetweenSetLength: 0, cooldownLength: 500, exercises: exercises),
      
      WorkoutModel(name: "Doge", type: .Strength, length: 20, warmupLength: 500, intervalLength: 40, restLength: 30, numberOfIntervals: 10, numberOfSets: 2, restBetweenSetLength: 0, cooldownLength: 500, exercises: exercises),
      
      WorkoutModel(name: "Cyborg", type: .Strength, length: 20, warmupLength: 500, intervalLength: 45, restLength: 20, numberOfIntervals: 10, numberOfSets: 2, restBetweenSetLength: 0, cooldownLength: 500, exercises: exercises),
      
      WorkoutModel(name: "Shinobi", type: .Strength, length: 20, warmupLength: 500, intervalLength: 60, restLength: 20, numberOfIntervals: 10, numberOfSets: 2, restBetweenSetLength: 0, cooldownLength: 500, exercises: exercises),
      
      WorkoutModel(name: "光線竜", type: .HIIT, length: 30, warmupLength: 500, intervalLength: 75, restLength: 10, numberOfIntervals: 10, numberOfSets: 3, restBetweenSetLength: 0, cooldownLength: 500, exercises: exercises),
      
      WorkoutModel(name: "Test", type: .Strength, length: 20, warmupLength: 5, intervalLength: 5, restLength: 5, numberOfIntervals: 3, numberOfSets: 2, restBetweenSetLength: 5, cooldownLength: 5, exercises: exercises),
    ]

    DataHandler.shared.insertWorkouts(workoutModels: workoutModels) {_ in }
  }

  
}
