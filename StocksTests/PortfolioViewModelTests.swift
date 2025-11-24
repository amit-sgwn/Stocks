//
//  PortfolioViewModelTests.swift
//  Stocks
//
//  Created by Amit Kumar on 20/11/25.
//

 
import XCTest
@testable import Stocks
 
@MainActor
final class PortfolioViewModelTests: XCTestCase {

    // MARK: - Mock Repo
    final class MockRepo: PortfolioRepositoryType {
        var result: Result<[Holding], Error> = .success([])

        func fetchPortfolio() async throws -> [Holding] {
            switch result {
            case .success(let items): return items
            case .failure(let e): throw e
            }
        }
    }

    // Helper factory
    private func makeHolding(symbol: String = "TST",
                             quantity: Int = 1,
                             ltp: Double = 100,
                             avgPrice: Double = 80,
                             close: Double = 90) -> Holding {
        Holding(symbol: symbol, quantity: quantity, ltp: ltp, avgPrice: avgPrice, close: close)
    }

    // MARK: - TESTS

    func testLoadSuccess_updatesHoldingsAndCalculations() async {
        // Arrange
        let h1 = makeHolding(symbol: "AAA", quantity: 2, ltp: 150, avgPrice: 120, close: 140)
        let h2 = makeHolding(symbol: "BBB", quantity: 1, ltp: 50, avgPrice: 40, close: 45)

        let mock = MockRepo()
        mock.result = .success([h1, h2])

        let vm = PortfolioViewModel(repo: mock)

        // Act
        await vm.load()

        // Assert
        XCTAssertEqual(vm.holdings.count, 2)

        if case .loaded = vm.state {} else {
            XCTFail("Expected state to be .loaded")
        }

        // Accessing these properties is safe because test runs on the MainActor
        XCTAssertEqual(vm.currentValue, 350.0, accuracy: 0.001)
        XCTAssertEqual(vm.totalInvestment, 280.0, accuracy: 0.001)
        XCTAssertEqual(vm.totalPNL, 70.0, accuracy: 0.001)
        XCTAssertEqual(vm.todaysPNL, 25.0, accuracy: 0.001)
    }

    func testLoadFailure_setsErrorState() async {
        // Arrange
        let mock = MockRepo()
        mock.result = .failure(URLError(.notConnectedToInternet))

        let vm = PortfolioViewModel(repo: mock)

        // Act
        await vm.load()

        // Assert
        switch vm.state {
        case .error(let err):
            XCTAssertTrue(err is URLError)
        default:
            XCTFail("Expected .error state")
        }
    }

    func testCalculations_whenNoHoldings_areZero() async {
        let mock = MockRepo()
        mock.result = .success([])

        let vm = PortfolioViewModel(repo: mock)

        // No load required because holdings default is empty
        XCTAssertEqual(vm.holdings.count, 0)
        XCTAssertEqual(vm.currentValue, 0.0)
        XCTAssertEqual(vm.totalInvestment, 0.0)
        XCTAssertEqual(vm.totalPNL, 0.0)
        XCTAssertEqual(vm.todaysPNL, 0.0)
    }

    func testNegativePNL() async {
        let loss = makeHolding(symbol: "LOSS", quantity: 2, ltp: 50, avgPrice: 100, close: 90)

        let mock = MockRepo()
        mock.result = .success([loss])

        let vm = PortfolioViewModel(repo: mock)
        await vm.load()

        XCTAssertEqual(vm.totalPNL, -100.0, accuracy: 0.001)
        XCTAssertEqual(vm.todaysPNL, -80.0, accuracy: 0.001)
    }

    func testZeroInvestmentEdgeCase() async {
        let h = makeHolding(symbol: "FREE", quantity: 5, ltp: 120, avgPrice: 0, close: 100)

        let mock = MockRepo()
        mock.result = .success([h])

        let vm = PortfolioViewModel(repo: mock)
        await vm.load()

        XCTAssertEqual(vm.totalInvestment, 0.0, accuracy: 0.001)
        XCTAssertEqual(vm.currentValue, 600.0, accuracy: 0.001)
        XCTAssertEqual(vm.totalPNL, 600.0, accuracy: 0.001)
        XCTAssertEqual(vm.todaysPNL, 100.0, accuracy: 0.001)
    }
}
