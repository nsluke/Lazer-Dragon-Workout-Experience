//
//  DataHandler.swift
//  CodeDump
//
//  Created by Luke Solomon on 5/13/20.
//  Copyright © 2020 Observatory. All rights reserved.
//


import Foundation
import CoreData
import UIKit


class DataHandler {
  
  public static var shared:DataHandler!
  
  
  private static var workouts = [Workout]()
  private var workoutModels = [WorkoutModel]()
  
  private var coreDataHandler:CoreDataHandler!
  
  init(container: NSPersistentContainer) {
    self.coreDataHandler = CoreDataHandler(container: container)
  }
  
  private static var dispatchQueue = DispatchQueue.init(
    label: "DataManagrr",
    qos: .background,
    attributes: .concurrent,
    autoreleaseFrequency: .inherit,
    target: .none
  )
  
  
  func getWorkouts(completion: @escaping (Result<[Workout], Error>) -> ()) {
    print("DataManager getting workouts")

    DataHandler.dispatchQueue.sync {
      if DataHandler.workouts.count == 0 {
        print("DataManager has \(DataHandler.workouts.count) workouts")
        self.coreDataHandler.fetchWorkouts(completion: { (result) in
            if case .success(let workouts) = result {
              print("DataManager: Core Data returned \(workouts.count) workouts")
              DataHandler.workouts = workouts
              completion(.success(workouts))
            } else if case .failure = result {
              //make a network call?
              print("DataManager.getWorkouts: Core Data returned an error")
            }
          })
      } else {
        print("DataManager is returning \(DataHandler.workouts.count) from memory")
        completion(.success(DataHandler.workouts))
      }
    }
  }
  
  
  func insertWorkouts(workoutModels: [WorkoutModel], completion: @escaping (Result<Bool, Error>) -> ()) {
    DataHandler.dispatchQueue.sync {
//      let workoutObjcs = self.coreDataHandler.workoutModelsToWorkouts(workoutModels: workoutModels)
      print()
      print("DataManager.insertWorkouts: Adding \(workoutModels.count) to CoreData")
      print()
      self.coreDataHandler.insertWorkouts(workoutModels: workoutModels) { (result) in
        self.coreDataHandler.saveContext {
          completion(.success(true))
        }
      }
    }
  }
  
  
  func deleteWorkout(workoutName: String, completion: @escaping () -> ()) {
    DataHandler.dispatchQueue.sync {
      for (i,workout) in DataHandler.workouts.enumerated() {
        if workout.name == workoutName && i < DataHandler.workouts.count {
          DataHandler.workouts.remove(at: i)
          self.coreDataHandler.deleteWorkoutWithName(name: workoutName) { result in
            self.coreDataHandler.saveContext {
              print("DataManager: Workout \(workoutName) successfully deleted")
              completion()
            }
          }
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
      var exercises = [ExerciseModel]()
      
      for exercise in workout.exercises {
        let exerciseModel = ExerciseModel(
          name: exercise.name!,
          image: UIImage(data: exercise.image!)!,
          splitLength: Int(exercise.splitLength)
        )
        exercises.append(exerciseModel)
      }
      
      
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
