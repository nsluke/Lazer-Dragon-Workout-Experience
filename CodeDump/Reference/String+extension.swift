//
//  String+extension.swift
//  CodeDump
//
//  Created by Luke Solomon on 9/2/20.
//  Copyright © 2020 Observatory. All rights reserved.
//

import Foundation

extension String {
  
  static func timeToFormattedString(time:Int) -> String {
    let time = time
    
    // TODO: put new timer logic here
    let hours = time/3600
    
    var minutes = time / 60
    
    var seconds = time % 60
    
    
    if hours > 1 {
      minutes = (time % (60 * 60)) / 60
    }
    
    if minutes > 1 {
      seconds = time % 60
    }
    
    var formattedTimeString = ""
    
    if hours < 1 {
      formattedTimeString = String(format: "%2i:%02i", minutes, seconds)
    } else {
      formattedTimeString = String(format: "%2i:%02i:%02i", hours, minutes, seconds)
    }
    
    print("time: \(time)")
    print("hours: \(hours)")
    print("minutes: \(minutes)")
    print("seconds: \(seconds)")
    print("formattedTimeString: \(formattedTimeString)")
    
    return formattedTimeString
  }
  
  func containsNonEnglishCharacters() -> Bool { // TODO: Make this work!
    let characterset = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
    
    if self.rangeOfCharacter(from: characterset) == nil {
      return true
    }
    
    return false
  }
  
}
