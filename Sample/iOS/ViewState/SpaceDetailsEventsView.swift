//
//  SpaceDetailsEventsView.swift
//  LilloMaps
//
//  Created by Raul Lermen on 22/08/22.
//

import SwiftUI

struct SpaceDetailsEventsView: View {
    
    @EnvironmentObject var dataController: AppDataController
    
    @State private var events: spaceEventsState = .none
    @State private var selectedEventId: Int?
    
    let spaceId: Int
    
    private enum spaceEventsState {
        case none
        case loading
        case success(events: [EventModel])
        case error(error: ApplicationError)
    }
    
    //MARK: Life Cycle
    
    var body: some View {
        Section(header: Text("Eventos nesse espaço")) {
            buildSpaceEvents()
        }.onLoad {
            Task { @MainActor in
                await requestSpaceEvents()
            }
        }
    }
    
    @ViewBuilder
    private func buildSpaceEvents() -> some View {
        switch events {
        case let .success(events):
            if events.count > 0 {
                ForEach(events, id: \.id) { event in
                    EventListView(event: event)
                        .onTapGesture {
                            selectedEventId = event.id
                        }
                }
                .sheet(item: $selectedEventId) { id in
                    EventDetailsView(eventId: id)
                        .environmentObject(dataController)
                }
            } else {
                Text("Nenhum evento encontrado.")
            }
        default:
            VStack { }
        }
    }
    
    @MainActor
    private func requestSpaceEvents() async {
        events = .loading
        let result = await dataController.loadSpaceEvents(spaceId)
        switch result {
        case .success(let data):
            self.events = .success(events: data)
        case .failure(let error):
            self.events = .error(error: error)
        }
    }
}
