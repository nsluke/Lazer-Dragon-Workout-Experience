//
//  Exercise+CoreDataProperties.swift
//  CodeDump
//
//  Created by Luke Solomon on 6/25/20.
//  Copyright © 2020 Observatory. All rights reserved.
//
//

import Foundation
import CoreData
import UIKit

extension Exercise {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Exercise> {
        return NSFetchRequest<Exercise>(entityName: "Exercise")
    }

    @NSManaged public var image: Data?
    @NSManaged public var name: String?
    @NSManaged public var splitLength: Int16
    @NSManaged public var order: Int16
    @NSManaged public var workout: Workout?

}

