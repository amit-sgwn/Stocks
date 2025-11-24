//
//  AppError.swift
//  Stocks
//
//  Created by Amit Kumar on 19/11/25.
//


import Foundation

enum AppError: Error, Equatable {
    case network(underlying: Error)
    case decoding(underlying: Error)
    case server(statusCode: Int)
    case noData
    case cache(underlying: Error)
    case unknown

    static func map(_ error: Error) -> AppError {
        if let urlError = error as? URLError {
            return .network(underlying: urlError)
        }
        if let decoding = error as? DecodingError {
            return .decoding(underlying: decoding)
        }
        return .unknown
    }
    
    static func == (lhs: AppError, rhs: AppError) -> Bool {
          switch (lhs, rhs) {
          case (.network, .network),
               (.decoding, .decoding),
               (.noData, .noData),
               (.unknown, .unknown),
               (.cache, .cache):
              return true

          case (.server(let a), .server(let b)):
              return a == b

          default:
              return false
          }
      }
}
