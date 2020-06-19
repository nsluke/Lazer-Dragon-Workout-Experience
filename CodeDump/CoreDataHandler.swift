//
//  CoreDataHandler.swift
//  CodeDump
//
//  Created by Luke Solomon on 5/13/20.
//  Copyright © 2020 Observatory. All rights reserved.
//

import Foundation
import UIKit
import CoreData




class CoreDataHandler: NSObject {
//  static let moduleName = "outrun"
  
  public static let sharedInstance = CoreDataHandler()

  func saveWorkout(workoutModel:WorkoutModel, completion: @escaping () -> Void) {
    
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
      return
    }

    let managedContext = appDelegate.persistentContainer.viewContext
    
    let entity = NSEntityDescription.entity(forEntityName: "Workout", in: managedContext)!
    let workoutEntity = NSManagedObject(entity: entity, insertInto: managedContext)
    
    // 3
    workoutEntity.setValue(workoutModel.name, forKeyPath: "name")
    workoutEntity.setValue(workoutModel.type.rawValue , forKeyPath: "type")
    workoutEntity.setValue(workoutModel.length , forKeyPath: "length")
    
    workoutEntity.setValue(workoutModel.warmupLength , forKeyPath: "warmupLength")
    workoutEntity.setValue(workoutModel.intervalLength , forKeyPath: "intervalLength")
    workoutEntity.setValue(workoutModel.restLength , forKeyPath: "restLength")
    
    workoutEntity.setValue(workoutModel.numberOfIntervals , forKeyPath: "numberOfIntervals")
    workoutEntity.setValue(workoutModel.numberOfSets , forKeyPath: "numberOfSets")
    workoutEntity.setValue(workoutModel.cooldownLength , forKeyPath: "cooldownLength")

    //    workoutEntity.setValue(workoutModel.exercises , forKeyPath: "exercises")
    
    // 4
    do {
      try managedContext.save()
    } catch let error as NSError {
      print("Could not save Workouts. \(error), \(error.userInfo)")
    }
  }
  
  
  func fetchWorkouts(completion: ([WorkoutModel]) -> Void) {
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
      return
    }
    
    let managedContext = appDelegate.persistentContainer.viewContext
    
    //2
//    let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Workout")
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Workout")
    
    //3
    do {
      let workouts = try managedContext.fetch(fetchRequest) as! [Workout]
      
      var result = [WorkoutModel]()
      
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

        // do exercises later?
        
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
          cooldownLength: workoutCooldownLength)
        result.append(workoutModel)
        
      }
      completion(result)
      
    } catch let error as NSError {
      print("Could not fetch Workouts. \(error), \(error.userInfo)")
    }
  }
  
  
  
}
