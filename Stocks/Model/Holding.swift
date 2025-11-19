//
//  Holding.swift
//  Stocks
//
//  Created by Amit Kumar on 17/11/25.
//


// Models/Holding.swift
import Foundation
 
struct Holding: Codable {
    let symbol: String
    let quantity: Int
    let ltp: Double
    let avgPrice: Double
    let close: Double
}
