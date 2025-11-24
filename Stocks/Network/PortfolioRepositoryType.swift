//
//  PortfolioRepositoryType.swift
//  Stocks
//
//  Created by Amit Kumar on 17/11/25.
//


// Repositories/PortfolioRepository.swift
import Foundation

protocol PortfolioRepositoryType {
    func fetchPortfolio() async throws -> [Holding]
}

final class PortfolioRepository: PortfolioRepositoryType {

    private let network: NetworkServiceType
    private let cache = CacheService()
    private let cacheFile = "portfolio_cache.json"
    private let url: URL

    init(network: NetworkServiceType = NetworkService(),
         url: URL = URL(string: "https://35dee773a9ec441e9f38d5fc249406ce.api.mockbin.io/")!) {
        self.network = network
        self.url = url
    }

    func fetchPortfolio() async throws -> [Holding] {

         
        if cache.exists(cacheFile) {
            do {
                let data = try cache.load(cacheFile)
                let resp = try JSONDecoder().decode(PortfolioResponse.self, from: data)
                return resp.data.userHolding
            } catch {
                 
            }
        }

        
        let data = try await network.fetchData(from: url)

         
        try? cache.save(data, as: cacheFile)

        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let resp = try decoder.decode(PortfolioResponse.self, from: data)
        return resp.data.userHolding
    }
}
