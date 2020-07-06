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


}
