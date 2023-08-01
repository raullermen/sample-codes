//
//  ApiNetwork.swift
//  LilloMaps
//
//  Created by Raul Lermen on 15/08/22.
//

import Foundation

protocol Endpoint {
    var path: String { get }
    var parameters: [String: Any]? { get }
    var method: NetworkMethod { get }
    var body: Data? { get }
}

enum NetworkMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

enum ApplicationError: Error {
    case requestFailed(code: Int)
    case emptyResult
    case parseFailed
    case undefinedError
    
    var description: String {
        return "Erro generico"
    }
}

class NetworkService {
    
    private let networkCache: NetworkCacheProtocol?

    init(networkCache: NetworkCacheProtocol? = nil) {
        self.networkCache = networkCache
    }
    
    func request<T: Decodable>(_ endpoint: Endpoint, type: T.Type) async throws -> Result<T, ApplicationError> {
        let url = endpoint.buildURL()
        
        if let cacheData = networkCache?.getCache(url: url),
           let decoded = try? JSONDecoder().decode(T.self, from: cacheData) {
            return .success(decoded)
        }
        
        var request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        request.httpMethod = endpoint.method.rawValue
        if let body = endpoint.body {
            request.httpBody = body
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        let code: Int = (response as? HTTPURLResponse)?.statusCode ?? -1
        
        do {
            let decoded = try JSONDecoder().decode(T.self, from: data)
            networkCache?.saveCache(url: url, data: data)
            return .success(decoded)
        } catch let error {
            print(error)
            return .failure(.requestFailed(code: code))
        }
    }
}
