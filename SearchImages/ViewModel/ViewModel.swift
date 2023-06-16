//
//  ViewModel.swift
//  SearchImages
//
//  Created by David Mikhailov on 28/04/2023.
//

import Foundation
import Alamofire
import CoreData
import Dependency

class ViewModel: ObservableObject {
    
    @Published var items: [ModelImage] = []
    
    // Dependency Injection
    @Dependency(\.dataManager) var dataManager
    
    init() {
        fetchData()
    }
    
    func fetchData() {
        dataManager.fetchData()
        dataManager.dataPublisher
            .sink(receiveCompletion: { _ in }) { models in
                self.items = models
            }
            .store(in: &dataManager.cancellable)
    }
}
