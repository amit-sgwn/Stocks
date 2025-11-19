//
//  PortfolioViewModel.swift
//  Stocks
//
//  Created by Amit Kumar on 17/11/25.
//


// ViewModels/PortfolioViewModel.swift
import Foundation
import Combine

@MainActor
final class PortfolioViewModel: ObservableObject {
    enum State {
        case idle
        case loading
        case loaded
        case error(Error)
    }
    
    // Outputs
    @Published private(set) var holdings: [Holding] = []
    @Published private(set) var state: State = .idle
    @Published var isSummaryExpanded: Bool = false
    
    private let repo: PortfolioRepositoryType
    
    init(repo: PortfolioRepositoryType = PortfolioRepository()) {
        self.repo = repo
    }
    
    // MARK: - Fetching
    func load() async {
        state = .loading
        do {
            let items = try await repo.fetchPortfolio()
            holdings = items
            state = .loaded
        } catch {
            state = .error(error)
        }
    }
    
    // MARK: - Calculations
    var currentValue: Double {
        holdings.reduce(0.0) { $0 + ($1.ltp * Double($1.quantity)) }
    }
    
    var totalInvestment: Double {
        holdings.reduce(0.0) { $0 + ($1.avgPrice * Double($1.quantity)) }
    }
    
    var totalPNL: Double {
        currentValue - totalInvestment
    }
    
    var todaysPNL: Double {
        holdings.reduce(0.0) { partial, h in
            partial + ((h.ltp - h.close) * Double(h.quantity))
        }
    }
}
