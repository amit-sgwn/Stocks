//
//  PortfolioResponse.swift
//  Stocks
//
//  Created by Amit Kumar on 17/11/25.
//


// Models/PortfolioResponse.swift
import Foundation

struct PortfolioResponse: Codable {
    let data: PortfolioData
}

struct PortfolioData: Codable {
    let userHolding: [Holding]
}
