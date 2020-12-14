//
//  Protocols.swift
//  CodeDump
//
//  Created by Luke Solomon on 12/11/20.
//  Copyright © 2020 Observatory. All rights reserved.
//

import UIKit

protocol OutrunTabBarPresenterToViewProtocol: class {

}

protocol OutrunTabBarInteractorToPresenterProtocol: class {
  
}

protocol OutrunTabBarPresentorToInteractorProtocol: class {
    var presenter: OutrunTabBarInteractorToPresenterProtocol? { get set }
//    var news: [LiveNewsModel]? { get }
    
//    func fetchLiveNews()
}

protocol OutrunTabBarViewToPresenterProtocol: class {
    var view: OutrunTabBarPresenterToViewProtocol? { get set }
    var interactor: OutrunTabBarPresentorToInteractorProtocol? { get set }
    var router: OutrunTabBarPresenterToRouterProtocol? { get set }
    
    func updateView()
//    func getNewsListCount() -> Int?
//    func getNews(index: Int) -> OutrunTabBarModel?
}

protocol OutrunTabBarPresenterToRouterProtocol: class {
  static func createModule() -> OutrunTabBar
}
