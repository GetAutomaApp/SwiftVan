//
//  AnyDict.swift
//  SwiftVan
//
//  Created by Simon Ferns on 10/13/25.
//
import Foundation

public extension Dictionary where Key == String {
    func string(_ key: String) -> String? {
        self[key] as? String
    }
    
    func int(_ key: String) -> Int? {
        self[key] as? Int
    }
    
    func double(_ key: String) -> Double? {
        self[key] as? Double
    }
    
    func bool(_ key: String) -> Bool? {
        self[key] as? Bool
    }
    
    func array(_ key: String) -> [Any]? {
        self[key] as? [Any]
    }
    
    func dictionary(_ key: String) -> [String: Any]? {
        self[key] as? [String: Any]
    }
    
    func function(_ key: String) -> (() -> Void)? {
        self[key] as? (() -> Void)
    }
}

public typealias DictValue = [String: Any]
