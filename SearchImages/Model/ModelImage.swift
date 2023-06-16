//
//  ModelImage.swift
//  SearchImages
//
//  Created by David Mikhailov on 28/04/2023.
//

import Foundation

struct ModelImage: Identifiable {
    let id: UUID = UUID()
    let imageURL: URL?
    let likes: Int
    let comments: Int
}
