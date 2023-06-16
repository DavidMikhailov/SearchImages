//
//  DataManager.swift
//  SearchImages
//
//  Created by David Mikhailov on 28/04/2023.
//

import Foundation
import CoreData
import SwiftUI
import Alamofire
import Combine

protocol DataManagerProtocol {
    func fetchData()
    var dataPublisher: CurrentValueSubject<[ModelImage], Error> { get }
    var cancellable: [AnyCancellable] { get set }
}

class DataManager: NSObject, DataManagerProtocol, ObservableObject {
    
    @Published var images: [ModelImage] = [ModelImage]()
    var dataPublisher = CurrentValueSubject<[ModelImage], Error>([])
    var cancellable: [AnyCancellable] = []
    
    override init() {
        super.init()
        fetchData()
    }
    
    func fetchData() {
        fetchDataFromCoreData()
            .filter {!$0.isEmpty}
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }) { [weak self] models in
                self?.dataPublisher.send(models)
                self?.fetchFromApi()
            }
            .store(in: &cancellable)
        
        fetchDataFromCoreData()
            .filter {$0.isEmpty}
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }) { [weak self] models in
                self?.fetchFromApi()
            }
            .store(in: &cancellable)
    }
    
    private func fetchFromApi() {
        fetchDataFromApi()
            .filter {!$0.isEmpty}
            .handleEvents(receiveOutput: { [weak self] in
                self?.saveData($0)
            })
            .sink(receiveCompletion: { _ in }) { [weak self] models in
                self?.dataPublisher.send(models)
            }
            .store(in: &cancellable)
    }
    
    private func fetchDataFromApi() -> AnyPublisher<[ModelImage], Never> {
        
        AF.request(Constants.baseUrl,
                   parameters: ["key": Constants.apiKey])
        .publishDecodable(type:  ResultApi.self)
        .map { response in
            switch response.result {
            case .success(let models):
                return models.hits
                    .compactMap { ModelImage(imageURL: URL(string: $0.userImageURL ?? ""),
                                             likes: $0.likes ?? 0,
                                             comments: $0.comments ?? 0) }
                    .filter { $0.comments > 30 &&
                        $0.likes > 30 }
                    .sorted(by: { $0.likes > $1.likes })
            case .failure(let error):
                print(error.localizedDescription)
                return []
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func fetchDataFromCoreData() -> AnyPublisher<[ModelImage], Never> {
        loadData()
            .map { return $0
                    .filter { $0.comments > 30 && $0.likes > 30 }
                    .sorted(by: { $0.likes > $1.likes })
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - CoreData
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Model")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error {
                fatalError("Unresolved error \(error), \(error.localizedDescription)")
            }
        })
        return container
    }()
    
    // MARK: - Methods
    private func saveData(_ models: [ModelImage]) {
        let context = persistentContainer.viewContext
        let managedContext = context
        let entity = NSEntityDescription.entity(forEntityName: "SavedImage", in: managedContext)!
        
        models.forEach { model in
            let imageObject = NSManagedObject(entity: entity, insertInto: managedContext)
            imageObject.setValue(model.id, forKeyPath: "id")
            imageObject.setValue(model.likes, forKeyPath: "likes")
            imageObject.setValue(model.comments, forKeyPath: "comments")
            imageObject.setValue(model.imageURL, forKeyPath: "imageURL")
            
            do {
                try managedContext.save()
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
        }
    }
    
    private func loadData() -> AnyPublisher<[ModelImage], Never> {
        Just(SavedImage.fetchRequest())
            .compactMap {
                try? persistentContainer.viewContext.fetch($0) as? [SavedImage]
            }
            .map {
                return $0.map { ModelImage(imageURL: $0.imageURL,
                                           likes: Int($0.likes),
                                           comments: Int($0.comments))
                }
            }
            .eraseToAnyPublisher()
    }
}
