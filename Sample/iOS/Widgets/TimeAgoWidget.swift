//
//  TimeAgoWidget.swift
//  GameBase
//
//  Created by Raul Lermen on 14/11/20.
//  Copyright © 2020 Raul Lermen. All rights reserved.
//

import WidgetKit
import SwiftUI
import Intents

struct TimeAgoEntry: TimelineEntry {
    let date: Date
    var placeholder: Bool = false
    let game: GameCodable?
    let image: Image?
    let configuration: ConfigurationIntent
}

struct TimeAgoProvider: IntentTimelineProvider {
    
    func placeholder(in context: Context) -> TimeAgoEntry {
        TimeAgoEntry(date: Date(), placeholder: true, game: nil, image: nil, configuration: ConfigurationIntent())
    }
    
    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (TimeAgoEntry) -> ()) {
        let entry = TimeAgoEntry(date: Date(), placeholder: true, game: nil, image: nil, configuration: configuration)
        completion(entry)
    }
    
    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let model = GameBaseWidgetModel(
            repository: CoreDataRepository(
                context: CoreDataContext.build()), localStorage: UserLocalStorage()
        )
        
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        if let game = model.getTimeAgoGame(),
           let imageUrl = game.screenshots?.shuffled().first?.originalURL {
            model.downloadImageForUrl(imageUrl, completion: { image in
                let entries = [TimeAgoEntry(date: startOfDay, game: game, image: image, configuration: configuration)]
                let timeline = Timeline(entries: entries, policy: .after(endOfDay))
                completion(timeline)
            })
        } else {
            let entries = [TimeAgoEntry(date: startOfDay, game: nil, image: nil, configuration: configuration)]
            let timeline = Timeline(entries: entries, policy: .after(endOfDay))
            completion(timeline)
        }
    }
}

struct TimeAgoEntryView : View {
    
    var entry: TimeAgoProvider.Entry
    
    static func title(game: GameCodable?) -> String {
        guard let game = game else { return "ThisGameWasReleasedThisDay".localized }
        let today = Date()
        let name = game.name
        if game.first_release_date?.date.day == today.day {
            return "\(name) \("WasReleasedThisDay".localized)"
        }
        if game.first_release_date?.date.weekOfYear == today.weekOfYear {
            return "\(name) \("WasReleasedThisWeek".localized)"
        }
        if game.first_release_date?.date.month == today.month {
            return "\(name) \("WasReleasedThisMonth".localized)"
        }
        return ""
    }
    
    static func description(game: GameCodable?, placeholder: Bool) -> String {
        let description = placeholder ? "FewYeasAgo".localized : "NoMemoryToday".localized
        if let game = game,
           let todayYear = Int(Date().year),
           let firstReleaseDateYear = game.first_release_date?.date.year,
           let gameYearInt = Int(firstReleaseDateYear) {
            let calc = todayYear - gameYearInt
            return "\(String(calc)) \(calc == 1 ? "YearAgo".localized : "YearsAgo".localized)"
        }
        return description
    }
    
    var body: some View {
        TimeAgoView(
            title: TimeAgoEntryView.title(game: entry.game),
            description: TimeAgoEntryView.description(game: entry.game, placeholder: entry.placeholder),
            image: entry.image,
            placeholder: entry.placeholder,
            onTouch: nil
        )
        .widgetURL(WidgetDeepLink.deeplinkForGame(gameId: entry.game?.id ?? 0))
    }
}

struct TimeAgoWidget: Widget {
    
    static let kind: String = "GameBaseWidgetTimeAgo"
    
    var body: some WidgetConfiguration {
        IntentConfiguration(
            kind: TimeAgoWidget.kind,
            intent: ConfigurationIntent.self,
            provider: TimeAgoProvider()
        ) { entry in
            TimeAgoEntryView(entry: entry)
        }
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .configurationDisplayName("TimeAgoWidgetTitle".localized)
        .description("TimeAgoWidgetDescription".localized)
    }
}

