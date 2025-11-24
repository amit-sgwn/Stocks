//
//  CacheServiceType.swift
//  Stocks
//
//  Created by Amit Kumar on 19/11/25.
//


import Foundation

protocol CacheServiceType {
    func save(_ data: Data, as filename: String) throws
    func load(_ filename: String) throws -> Data
    func exists(_ filename: String) -> Bool
}

final class CacheService: CacheServiceType {
    private let directory: URL

    init(directory: URL? = nil) {
        if let directory = directory {
            self.directory = directory
        } else {
            self.directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        }
    }

    func save(_ data: Data, as filename: String) throws {
        let url = directory.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)
    }

    func load(_ filename: String) throws -> Data {
        let url = directory.appendingPathComponent(filename)
        return try Data(contentsOf: url)
    }

    func exists(_ filename: String) -> Bool {
        let url = directory.appendingPathComponent(filename)
        return FileManager.default.fileExists(atPath: url.path)
    }
}