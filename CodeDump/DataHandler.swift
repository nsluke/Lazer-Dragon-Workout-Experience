//
//  DataHandler.swift
//  CodeDump
//
//  Created by Luke Solomon on 5/13/20.
//  Copyright © 2020 Observatory. All rights reserved.
//

import Foundation


struct DataHandler {
  
  public static var shared = DataHandler()
  
  var workouts = [Workout]()
  
  
  mutating func getWorkouts(completion: @escaping ([Workout]) -> ()) {
    if workouts.count == 0 {
      CoreDataHandler.shared.fetchWorkouts(completion: { (result) in
        if result.count == 0 {
          //make a network call?
          print("DataManager: Core Data returned \(result)")
        } else{
          self.workouts = result
          completion(result)
        }
      })
    } else {
      completion(workouts)
    }
  }
  
  mutating func saveWorkouts(workoutModels: [WorkoutModel], completion: @escaping () -> ()) {
    let workoutObjcs = CoreDataHandler.shared.workoutModelsToWorkouts(workoutModels: workoutModels)
//    self.workouts.append(contentsOf: workoutObjcs)
    CoreDataHandler.shared.saveWorkouts(workoutModels: workoutModels) {
      completion()
    }
  }
  
  mutating func deleteWorkout(workoutName: String, completion: @escaping () -> ()) {
    for (i,workout) in workouts.enumerated() {
      if workout.name == workoutName && i < workouts.count {
        workouts.remove(at: i)
        CoreDataHandler.shared.deleteWorkoutWithName(name: workoutName) {
          completion()
          print("DataManager: Workout successfully deleted")
        }
      }
    }
  }
  
  func workoutsToWorkoutModels(workouts: [Workout]) -> [WorkoutModel] {
    var workoutModels = [WorkoutModel]()
    
      for workout in workouts {
        let workoutName = workout.name!
        
        //Converting the string back into an enum value
        let workoutType = workout.type!
        var convertedWorkoutType = WorkoutType(rawValue: "")
        
        switch workoutType {
        case WorkoutType.HIIT.rawValue:
          convertedWorkoutType = .HIIT
        case WorkoutType.Run.rawValue:
          convertedWorkoutType = .Run
        case WorkoutType.Yoga.rawValue:
          convertedWorkoutType = .Yoga
        case WorkoutType.Strength.rawValue:
          convertedWorkoutType = .Strength
        case WorkoutType.Custom.rawValue:
          convertedWorkoutType = .Custom
        default:
          fatalError("undefined workoutType fetched from CoreData")
          convertedWorkoutType = .Custom
        }
        
        let workoutLength = Int(workout.length)
        let workoutWarmupLength = Int(workout.warmupLength)
        let workoutIntervalLength = Int(workout.intervalLength)
        let workoutRestLength = Int(workout.restLength)
        let workoutNumberOfIntervals = Int(workout.numberOfIntervals)
        let workoutNumberOfSets = Int(workout.numberOfSets)
        let workoutRestBetweenSetLength = Int(workout.restBetweenSetLength)
        let workoutCooldownLength = Int(workout.cooldownLength)
        let exercises = workout.exercises?.allObjects as! [ExerciseModel]
        
        let workoutModel = WorkoutModel(
          name: workoutName,
          type: convertedWorkoutType!,
          length: workoutLength,
          warmupLength: workoutWarmupLength,
          intervalLength: workoutIntervalLength,
          restLength: workoutRestLength,
          numberOfIntervals: workoutNumberOfIntervals,
          numberOfSets: workoutNumberOfSets,
          restBetweenSetLength: workoutRestBetweenSetLength,
          cooldownLength: workoutCooldownLength,
          exercises: exercises
        )
        workoutModels.append(workoutModel)
      }
    
    return workoutModels
  }

}
