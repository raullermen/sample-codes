//
//  Endpoint.swift
//  LilloMaps
//
//  Created by Raul Lermen on 16/08/22.
//

import Foundation

enum GovMapsEndpoint: Endpoint {
    case findEvents(filter: EventFilterModel)
    case findSpaces
    case findSpaceDetails(id: Int)
    case findSpaceEvents(id: Int)
    case findEventDetails(id: Int)
    case findSpaceLocation(id: Int) 
    
    var path: String {
        switch self {
        case .findEvents:
            return "/api/event/findByLocation"
        case .findSpaces:
            return "/api/space/findByEvents"
        case .findSpaceEvents:
            return "/api/event/findBySpace"
        case .findSpaceDetails, .findSpaceLocation:
            return "/api/space/findOne"
        case .findEventDetails:
            return "/api/event/find"
        }
    }
    
    var parameters: [String: Any]? {
        switch self {
        case let .findEvents(filter):
            var parameters = [
                "@files": "(avatar.avatarMedium):url",
                "@page": "\(String(filter.page))",
                "@limit": "\(String(filter.limit))",
                "@select": "id,singleUrl,name,subTitle,type,shortDescription,terms,project.name,project.singleUrl, user, owner.userId,num_sniic,classificacaoEtaria,project.name,project.singleUrl,occurrences.{*,space.{*}}"
            ]
            
            if let location = filter.location {
                let latitude = String(format: "%.2f", location.latitude)
                let longitude = String(format: "%.2f", location.longitude)
                parameters["_geoLocation"] = "GEONEAR(\(longitude),\(latitude),\(String(filter.zoon)))"
            }
            
            if let keyword = filter.keyword, !keyword.isEmpty {
                parameters["@keyword"] = keyword
            }
            
            if let periodo = filter.period {
                parameters["@from"] = periodo.endpointData.from
                parameters["@to"] = periodo.endpointData.to
            }
            
            if let ages = filter.ages, ages.count > 0 {
                parameters["classificacaoEtaria"] = "IN(\(ages.map { $0.rawValue }.joined(separator: ",")))"
            }
            
            if let languages = filter.languages, languages.count > 0 {
                parameters["term:linguagem"] = "IN(\(languages.map { $0.rawValue }.joined(separator: ",")))"
            }
            
            return parameters
            
        case .findSpaces:
            let period = FilterPeriod.thisMonth
            return ["@from": period.endpointData.from,
                    "@to": period.endpointData.to,
                    "@select": "id,name,location"]
            
        case let .findSpaceEvents(id):
            let period = FilterPeriod.thisMonth
            return ["@from": period.endpointData.from,
                    "@to": period.endpointData.to,
                    "spaceId": String(id),
                    "@files": "(avatar.avatarMedium):url",
                    "@select": "id,singleUrl,name,subTitle,type,shortDescription,terms,project.name,project.singleUrl, user, owner.userId,num_sniic,endereco,classificacaoEtaria"]
            
        case let .findSpaceDetails(id):
            return ["id": "EQ(\(String(id)))",
                    "@files": "(avatar.avatarMedium):url",
                    "@select": "id,singleUrl,name,subTitle,type,shortDescription,terms,project.name,project.singleUrl,user, owner.userId,num_sniic,endereco,acessibilidade,esfera,esfera_tipo,horario,site,emailPublico,telefonePublico,endereco,En_CEP,En_Nome_Logradouro,En_Num,En_Complemento,En_Bairro,En_Municipio,En_Estado"]
            
        case let .findSpaceLocation(id):
            return ["id": "EQ(\(String(id)))",
                    "@select": "id,name,endereco,location"]
            
        case let .findEventDetails(id):
            return ["id": "EQ(\(String(id)))",
                    "@files": "(avatar.avatarMedium):url",
                    "@select": "id,name,num_sniic,subTitle,shortDescription,longDescription,terms,telefonePublico,classificacaoEtaria,singleUrl,endereco.*,occurrences.*,readableOccurrences,project.*,youtube.*,fabebook.*,instagram.*,occurrences.space.endereco,occurrences.space.name"]
        }
    }
    
    var method: NetworkMethod { .get }
    
    var body: Data? { nil }
}

//MARK: Build URL
extension Endpoint {
    func buildURL() -> URL {
        var components = URLComponents()
        
        components.scheme = "http"
        components.host = "mapas.cultura.gov.br"
        components.path = path
        
        var queryItems: [URLQueryItem] = []
        
        for key in parameters?.keys.sorted() ?? [] {
            if let value = parameters?[key] as? String {
                queryItems.append(URLQueryItem(name: key, value: value))
            }
        }
        
        components.queryItems = queryItems
        
        return components.url ?? URL(string: "")!
    }
}
