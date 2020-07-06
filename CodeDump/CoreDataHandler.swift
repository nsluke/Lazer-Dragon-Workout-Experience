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
import Combine


enum CoreDataHandlerError: Error {
    case fetchFailure
    case saveFailure
}


struct CoreDataHandler {
  public static let shared = CoreDataHandler()
  
  
  let persistentContainer:NSPersistentContainer = {
    let appdelegate = UIApplication.shared.delegate as! AppDelegate
    let container = appdelegate.persistentContainer
    
    return container
  }()

  // MARK - Save
  
  func saveWorkout(workoutModel:WorkoutModel) {
    let workout = NSEntityDescription.insertNewObject(forEntityName: "Workout", into: persistentContainer.viewContext) as! Workout
    workout.name = workoutModel.name
    workout.type = workoutModel.type.rawValue
    workout.length = Int16(workoutModel.length)

    workout.warmupLength = Int16(workoutModel.warmupLength)
    workout.intervalLength = Int16(workoutModel.intervalLength)
    workout.restLength = Int16(workoutModel.restLength)
    workout.restBetweenSetLength = Int16(workoutModel.restBetweenSetLength)
    
    workout.numberOfIntervals = Int16(workoutModel.numberOfIntervals)
    workout.numberOfSets = Int16(workoutModel.numberOfSets)
    workout.cooldownLength = Int16(workoutModel.cooldownLength)
    
    do {
      try persistentContainer.viewContext.save()
    } catch let error as NSError {
      print("CoreDataHandlerL could not save Workouts - \(error) \(error.userInfo)")
    }
  }
  
  func saveWorkouts(workoutModels:[WorkoutModel], completion: @escaping () -> Void) {
    for workout in workoutModels {
      self.saveWorkout(workoutModel: workout)
    }

    do {
      try persistentContainer.viewContext.save()
      completion()
    } catch let error as NSError {
      print("CoreDataHandlerL could not save Workouts - \(error) \(error.userInfo)")
    }
  }
  

  
//  func saveExercise(exercise: Exercise) {
  func saveExercise(name: String) {
    let exercise = NSEntityDescription.insertNewObject(forEntityName: "Exercise", into: persistentContainer.viewContext) as! Exercise
//      exercise.image = exercise.image
      exercise.name = name
//      exercise.splitLength = exercise.splitLength
    do {
      try persistentContainer.viewContext.save()
    } catch let error as NSError {
      print("CoreDataHandler: could not save Exercise - \(error) \(error.userInfo)")
    }
  }

  // MARK - Memory OBJ to NSManagedObjects
  
  func workoutModelsToWorkouts(workoutModels:[WorkoutModel]) -> [Workout] {
    var workouts = [Workout]()
    
    for workoutModel in workoutModels {
      let workout = Workout(context:  persistentContainer.viewContext)
      workout.name = workoutModel.name
      workout.type = workoutModel.type.rawValue
      workout.length = Int16(workoutModel.length)

      workout.warmupLength = Int16(workoutModel.warmupLength)
      workout.intervalLength = Int16(workoutModel.intervalLength)
      workout.restLength = Int16(workoutModel.restLength)
      workout.restBetweenSetLength = Int16(workoutModel.restBetweenSetLength)
      
      workout.numberOfIntervals = Int16(workoutModel.numberOfIntervals)
      workout.numberOfSets = Int16(workoutModel.numberOfSets)
      workout.cooldownLength = Int16(workoutModel.cooldownLength)
      
      workouts.append(workout)
    }
    
    return workouts
  }
  
  // MARK - Fetch
  
  func fetchWorkouts(completion: ([Workout]) -> Void) {
    var results = [Workout]()
    
    let fetchRequest = NSFetchRequest<Workout>(entityName: "Workout")
    
    do {
      let workouts = try persistentContainer.viewContext.fetch(fetchRequest)
      results = workouts
      completion(results)
    } catch let error as NSError {
      print("CoreDataHandler: could not fetch workouts - \(error) \(error.userInfo)")
      completion([])
    }
  }
  
  func fetchWorkoutWithName(name: String, completion:(Workout?) -> Void) {
    let fetchRequest:NSFetchRequest<Workout> = Workout.fetchRequest()

    fetchRequest.predicate = NSPredicate(format: "name = %@", name)
    
    do {
      let workout = try persistentContainer.viewContext.fetch(fetchRequest).first
      completion(workout)
    } catch let error as NSError {
      print("CoreDataHandler: could not fetch workout \(name) - \(error) \(error.userInfo)")
      completion(nil)
    }
  }
  
}



   
//    let entity = NSEntityDescription.entity(forEntityName: "Workout", in: CoreDataHandler.managedContext)!
//    let workoutEntity = NSManagedObject(entity: entity, insertInto: CoreDataHandler.managedContext)
//
//
//    workoutEntity.setValue(workoutModel.name, forKeyPath: "name")
//    workoutEntity.setValue(workoutModel.type.rawValue , forKeyPath: "type")
//    workoutEntity.setValue(workoutModel.length , forKeyPath: "length")
//
//    workoutEntity.setValue(workoutModel.warmupLength , forKeyPath: "warmupLength")
//    workoutEntity.setValue(workoutModel.intervalLength , forKeyPath: "intervalLength")
//    workoutEntity.setValue(workoutModel.restLength , forKeyPath: "restLength")
//
//    workoutEntity.setValue(workoutModel.numberOfIntervals , forKeyPath: "numberOfIntervals")
//    workoutEntity.setValue(workoutModel.numberOfSets , forKeyPath: "numberOfSets")
//    workoutEntity.setValue(workoutModel.cooldownLength , forKeyPath: "cooldownLength")
//
//    //    workoutEntity.setValue(workoutModel.exercises , forKeyPath: "exercises")
//
//
//    do {
//      try CoreDataHandler.managedContext.save()
//      completion()
//    } catch let error as NSError {
//      print("Could not save Workouts. \(error), \(error.userInfo)")
//    }
    
//    do {
//      let workouts = try CoreDataHandler.managedContext.fetch(fetchRequest) as! [Workout]
//
//      var result = [WorkoutModel]()
//
//      for workout in workouts {
//        let workoutName = workout.name!
//
//        //Converting the string back into an enum value
//        let workoutType = workout.type!
//        var convertedWorkoutType = WorkoutType(rawValue: "")
//
//        switch workoutType {
//        case WorkoutType.HIIT.rawValue:
//          convertedWorkoutType = .HIIT
//        case WorkoutType.Run.rawValue:
//          convertedWorkoutType = .Run
//        case WorkoutType.Yoga.rawValue:
//          convertedWorkoutType = .Yoga
//        case WorkoutType.Strength.rawValue:
//          convertedWorkoutType = .Strength
//        case WorkoutType.Custom.rawValue:
//          convertedWorkoutType = .Custom
//        default:
//          fatalError("undefined workoutType fetched from CoreData")
//          convertedWorkoutType = .Custom
//        }
//
//        let workoutLength = Int(workout.length)
//        let workoutWarmupLength = Int(workout.warmupLength)
//        let workoutIntervalLength = Int(workout.intervalLength)
//        let workoutRestLength = Int(workout.restLength)
//        let workoutNumberOfIntervals = Int(workout.numberOfIntervals)
//        let workoutNumberOfSets = Int(workout.numberOfSets)
//        let workoutRestBetweenSetLength = Int(workout.restBetweenSetLength)
//        let workoutCooldownLength = Int(workout.cooldownLength)
//
//        // do exercises later?
//
//        let workoutModel = WorkoutModel(
//          name: workoutName,
//          type: convertedWorkoutType!,
//          length: workoutLength,
//          warmupLength: workoutWarmupLength,
//          intervalLength: workoutIntervalLength,
//          restLength: workoutRestLength,
//          numberOfIntervals: workoutNumberOfIntervals,
//          numberOfSets: workoutNumberOfSets,
//          restBetweenSetLength: workoutRestBetweenSetLength,
//          cooldownLength: workoutCooldownLength)
//        result.append(workoutModel)
//
//      }
//      completion(result)
//
//    } catch let error as NSError {
//      print("Could not fetch Workouts. \(error), \(error.userInfo)")
//    }
