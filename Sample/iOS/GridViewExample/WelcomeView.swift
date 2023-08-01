//
//  WelcomeView.swift
//  GameBase
//
//  Created by Raul Lermen on 13/02/21.
//  Copyright © 2021 Raul Lermen. All rights reserved.
//

import SwiftUI

struct WelcomeView: View {
    
    var minWidthWaterfall: CGFloat {
        switch UIDevice.current.userInterfaceIdiom {
        case .mac: return 200
        case .pad: return 200
        default: return 120
        }
    }
    
    let placeholders: [(id: String, imageUrl: String)]
    
    init() {
        var itens = [(id: String, imageUrl: String)]()
        for _ in 0...60 {
            itens.append((id: NSUUID().uuidString, imageUrl: WelcomeView.gameCoverURLs.randomElement() ?? ""))
        }
        placeholders = itens
    }
    
    var body: some View {
        ZStack {
            VStack {
                let columns = [GridItem(.adaptive(minimum: minWidthWaterfall), spacing: 0)]
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 0) {
                        ForEach(placeholders, id: \.id) { placeholder in
                            GameCoverView(gameTitle: "", imageUrl: placeholder.imageUrl, fillCover: false)
                                .contentShape(Rectangle())
                                .padding(.horizontal, Spacing.small)
                        }
                    }
                }
                .padding([.horizontal], 2)
            }.opacity(0.1)
            
            VStack {
                VStack(alignment: .center, spacing: 4) {
                    Text("Welcome".localized)
                        .foregroundColor(Theme.primaryTextColor)
                        .font(.title2)
                        .bold()
                    Text("WelcomeDescription".localized)
                        .foregroundColor(Theme.primaryTextColor)
                        .font(.callout)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
}

extension WelcomeView {
    static let gameCoverURLs: [String] = [
        "https://images.igdb.com/igdb/image/upload/t_cover_big/co5vmg.png",
        "https://images.igdb.com/igdb/image/upload/t_cover_big/co4ui8.png",
        "https://images.igdb.com/igdb/image/upload/t_cover_big/co2ekt.png",
        "https://images.igdb.com/igdb/image/upload/t_cover_big/co2uo9.png",
        "https://images.igdb.com/igdb/image/upload/t_cover_big/co209t.png",
        "https://images.igdb.com/igdb/image/upload/t_cover_big/co25u7.png",
        "https://images.igdb.com/igdb/image/upload/t_cover_big/co1zjy.png",
        "https://images.igdb.com/igdb/image/upload/t_cover_big/co213p.png",
        "https://images.igdb.com/igdb/image/upload/t_cover_big/co1r77.png",
        "https://images.igdb.com/igdb/image/upload/t_cover_big/co1wr1.png",
        "https://images.igdb.com/igdb/image/upload/t_cover_big/co289i.png"
    ]
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}
