//
//  MainView.swift
//  SearchImages
//
//  Created by David Mikhailov on 28/04/2023.
//

import SwiftUI
import Combine
import Kingfisher

struct MainView: View {
    
    @ObservedObject var viewModel = ViewModel()
    @State var showingPopup = false
    
    var body: some View {
        if #available(iOS 15.0, *) {
            List {
                ForEach(viewModel.items, id: \.likes) { item in
                    configureCell(item: item)
                }
            }
            .refreshable {
                viewModel.fetchData()
            }
            .listStyle(.inset)
        } else {
            // Fallback on earlier versions
        }
    }
    
    @ViewBuilder
    func configureCell(item: ModelImage) -> some View {
        ZStack(alignment: .bottom) {
            KFImage(item.imageURL)
                .resizable()
                .scaledToFill()
            HStack(spacing: 30) {
                Text(Constants.comments + String(item.comments))
                    .padding(4)
                    .background(Color.white)
                    .cornerRadius(8)
                Text(Constants.likes + String(item.likes))
                    .padding(4)
                    .background(Color.white)
                    .cornerRadius(8)
                Spacer()
            }
            .padding()
        }
    }
}


struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
