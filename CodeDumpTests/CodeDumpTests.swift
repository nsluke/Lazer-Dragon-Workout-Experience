//
//  CodeDumpTests.swift
//  CodeDumpTests
//
//  Created by Luke Solomon on 5/1/20.
//  Copyright © 2020 Observatory. All rights reserved.
//

import XCTest
@testable import Lazer_Dragon

class CodeDumpTests: XCTestCase {
  

  override func setUp() {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    

    
  }
  
  override func tearDownWithError() throws {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  }
  
  func testExample() throws {
    // This is an example of a functional test case.
    //      XCTAssertTrue()
  }
  
  func testPerformanceExample() throws {
    // This is an example of a performance test case.
    self.measure {
      // Put the code you want to measure the time of here.
    }
  }
  
  
  
}

import Foundation
import CoreData



class CoreDataTests: XCTestCase {
  
  let context = UnitTestHelpers.setUpInMemoryManagedObjectContext()
//  let viewModel = MainViewModel()
  
  override func setUpWithError() throws {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
  }
  
  override func tearDownWithError() throws {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  }
  
  func testExample() throws {
    
//
//    do {
//        try UnitTestHelpers.deleteAllObjects(objectType: ExampleObject.self, withContext: context)
//        try viewModel.createAnObject()
//        try viewModel.createAnObject()
//        try viewModel.createAnObject()
//    } catch {
//        if let vmerror = error as? ViewModelError {
//            print("error : \(vmerror.localizedDescription)")
//        }
//        XCTFail("Could not create objects")
//    }
//    //create a fetch request to retrieve all those objects
//    let fetchRequest = ExampleObject.fetchRequest() as NSFetchRequest<ExampleObject>
//    do {
//        let results = try context.fetch(fetchRequest)
//        XCTAssert(results.count == 3)
//    } catch {
//        XCTFail("Unabled to fetch objects")
//    }
    
  }
  
  func createTest() throws {
    
  }
  
  func readTest() throws {
    
  }
  
  func updateTest() throws {
    
  }
  
  func deleteTest() throws {
    
  }
  
}
