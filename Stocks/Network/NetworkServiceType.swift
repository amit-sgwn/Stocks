//
//  NetworkServiceType.swift
//  Stocks
//
//  Created by Amit Kumar on 17/11/25.
//


// Networking/NetworkService.swift
import Foundation

protocol NetworkServiceType {
    func fetchData(from url: URL) async throws -> Data
}

final class NetworkService: NetworkServiceType {
    func fetchData(from url: URL) async throws -> Data {
        var req = URLRequest(url: url)
        req.timeoutInterval = 20
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }
}
