//
//  LaunchHandler.swift
//  CodeDump
//
//  Created by Luke Solomon on 7/4/20.
//  Copyright © 2020 Observatory. All rights reserved.
//

import Foundation


struct LaunchHandler {
  
  public static var shared = LaunchHandler()
    
  
  func launch() {
    initialDataCheck()
  }
  
  func initialDataCheck() {
    CoreDataHandler.shared.fetchWorkouts(completion: { (result) in
      if result.count > 0 {
        DataHandler.shared.workouts = result
      } else {
        let workoutModels = [
          WorkoutModel(name: "Neko", type: .Strength, length: 20, warmupLength: 500, intervalLength: 30, restLength: 30, numberOfIntervals: 10, numberOfSets: 2, restBetweenSetLength: 0, cooldownLength: 500),
          
          WorkoutModel(name: "Doge", type: .Strength, length: 20, warmupLength: 500, intervalLength: 40, restLength: 30, numberOfIntervals: 10, numberOfSets: 2, restBetweenSetLength: 0, cooldownLength: 500),
          
          WorkoutModel(name: "Cyborg", type: .Strength, length: 20, warmupLength: 500, intervalLength: 45, restLength: 20, numberOfIntervals: 10, numberOfSets: 2, restBetweenSetLength: 0, cooldownLength: 500),
          
          WorkoutModel(name: "Shinobi", type: .Strength, length: 20, warmupLength: 500, intervalLength: 60, restLength: 20, numberOfIntervals: 10, numberOfSets: 2, restBetweenSetLength: 0, cooldownLength: 500),
          
          WorkoutModel(name: "光線竜", type: .HIIT, length: 30, warmupLength: 500, intervalLength: 75, restLength: 10, numberOfIntervals: 10, numberOfSets: 3, restBetweenSetLength: 0, cooldownLength: 500),
          
          WorkoutModel(name: "Test", type: .Strength, length: 20, warmupLength: 5, intervalLength: 5, restLength: 5, numberOfIntervals: 3, numberOfSets: 2, restBetweenSetLength: 5, cooldownLength: 5),
        ]
        
        
        
        DataHandler.shared.saveWorkouts(workoutModels: workoutModels) {}
      }
    })
  }
  
}
