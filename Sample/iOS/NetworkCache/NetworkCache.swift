//
//  NetworkCache.swift
//  LilloMaps
//
//  Created by Raul Lermen on 06/09/22.
//

import Foundation

protocol NetworkCacheProtocol  {
    func saveCache(url: URL, data: Data)
    func getCache(url: URL) -> Data?
}

class NetworkCache: NetworkCacheProtocol {
    
    private let cache = NSCache<NSString, NSString>()
    
    func saveCache(url: URL, data: Data) {
        if !url.absoluteString.contains("/file/") {
            let data = String(decoding: data, as: UTF8.self)
            cache.setObject(data as NSString, forKey: url.absoluteString as NSString)
        }
    }
    
    func getCache(url: URL) -> Data? {
        let cache = cache.object(forKey: url.absoluteString as NSString)
        let data: Data? = (cache as? String)?.data(using: .utf8)
        return data
    }
}

class NetworkCacheUserDefaults: NetworkCacheProtocol {
    
    private let userDefaults = UserDefaults(suiteName: "group.com.5e.lillomaps") ?? .standard
    
    func saveCache(url: URL, data: Data) {
        if !url.absoluteString.contains("/file/") {
            let data = String(decoding: data, as: UTF8.self)
            userDefaults.set(data, forKey: url.absoluteString)
            userDefaults.synchronize()
        }
    }
    
    func getCache(url: URL) -> Data? {
        let result = userDefaults.string(forKey: url.absoluteString)
        return result?.data(using: .utf8)
    }
}
