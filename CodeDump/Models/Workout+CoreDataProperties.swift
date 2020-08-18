//
//  Workout+CoreDataProperties.swift
//  CodeDump
//
//  Created by Luke Solomon on 6/25/20.
//  Copyright © 2020 Observatory. All rights reserved.
//
//

import Foundation
import CoreData


extension Workout {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Workout> {
        return NSFetchRequest<Workout>(entityName: "Workout")
    }

    @NSManaged public var cooldownLength: Int16
    @NSManaged public var intervalLength: Int16
    @NSManaged public var length: Int16
    @NSManaged public var name: String?
    @NSManaged public var numberOfIntervals: Int16
    @NSManaged public var numberOfSets: Int16
    @NSManaged public var restBetweenSetLength: Int16
    @NSManaged public var restLength: Int16
    @NSManaged public var type: String?
    @NSManaged public var warmupLength: Int16
    @NSManaged public var exercises: [Exercise]

}

// MARK: Generated accessors for exercises
extension Workout {

    @objc(addExercisesObject:)
    @NSManaged public func addToExercises(_ value: Exercise)

    @objc(removeExercisesObject:)
    @NSManaged public func removeFromExercises(_ value: Exercise)

    @objc(addExercises:)
    @NSManaged public func addToExercises(_ values: NSSet)

    @objc(removeExercises:)
    @NSManaged public func removeFromExercises(_ values: NSSet)

}
