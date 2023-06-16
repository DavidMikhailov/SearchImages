//
//  DependencyInjection.swift
//  SearchImages
//
//  Created by David Mikhailov on 28/04/2023.
//

import Foundation
import Dependency

private struct DataManagerKey: DependencyKey {
    static var currentValue: DataManagerProtocol = DataManager()
}

extension DependencyValues {
    var dataManager: DataManagerProtocol {
        get { Self[DataManagerKey.self] }
        set { Self[DataManagerKey.self] = newValue }
    }
}
