//
//  MockURLProtocol.swift
//  Stocks
//
//  Created by Amit Kumar on 20/11/25.
//

import XCTest
@testable import Stocks
import XCTest

// MARK: - Network Stub
final class MockURLProtocol: URLProtocol {

    static var handler: ((URLRequest) -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.handler else { return }
        let (response, data) = handler(request)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

final class PortfolioViewControllerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(MockURLProtocol.self)
    }

    override func tearDown() {
        URLProtocol.unregisterClass(MockURLProtocol.self)
        MockURLProtocol.handler = nil
        super.tearDown()
    }

    // find a view
    private func find<T: UIView>(_ v: UIView, _ type: T.Type) -> T? {
        if let cast = v as? T { return cast }
        for sub in v.subviews {
            if let found = find(sub, type) { return found }
        }
        return nil
    }

    private func waitUntil(_ timeout: TimeInterval = 2,
                           condition: @escaping () -> Bool) {
        let exp = expectation(description: "wait")
        let deadline = Date().addingTimeInterval(timeout)

        func poll() {
            if condition() { exp.fulfill(); return }
            if Date() > deadline { exp.fulfill(); return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: poll)
        }

        poll()
        wait(for: [exp], timeout: timeout + 1)
    }

    // MARK: - TESTS

    func testVCLoadsHoldings() {
        let json = """
        { "data": { "user_holding": [
          { "symbol": "AAPL", "quantity": 1, "ltp": 150, "avg_price": 100, "close": 120 }
        ]}}
        """.data(using: .utf8)!

        MockURLProtocol.handler = { _ in
            (HTTPURLResponse(url: URL(string: "https://x")!,
                             statusCode: 200,
                             httpVersion: nil,
                             headerFields: nil)!,
             json)
        }

        let vc = PortfolioViewController()
        vc.loadViewIfNeeded()

        guard let table = find(vc.view, UITableView.self) else {
            XCTFail("Table not found"); return
        }

        waitUntil { table.numberOfRows(inSection: 0) == 1 }
        XCTAssertEqual(table.numberOfRows(inSection: 0), 1)
    }

    func testTabSwitching() {
        let json = """
        { "data": { "user_holding": [
          { "symbol": "INFY", "quantity": 3, "ltp": 1500, "avg_price": 1400, "close": 1480 }
        ]}}
        """.data(using: .utf8)!

        MockURLProtocol.handler = { _ in
            (HTTPURLResponse(url: URL(string: "https://x")!,
                             statusCode: 200,
                             httpVersion: nil,
                             headerFields: nil)!,
             json)
        }

        let vc = PortfolioViewController()
        vc.loadViewIfNeeded()

        guard
            let table = find(vc.view, UITableView.self),
            let tabs = find(vc.view, TopTabView.self)
        else { XCTFail("missing views"); return }

        waitUntil { table.numberOfRows(inSection: 0) == 1 }
        XCTAssertEqual(table.numberOfRows(inSection: 0), 1)

        DispatchQueue.main.async { tabs.select(.positions, animated: false) }
        waitUntil { table.numberOfRows(inSection: 0) == 0 }

        DispatchQueue.main.async { tabs.select(.holdings, animated: false) }
        waitUntil { table.numberOfRows(inSection: 0) == 1 }
    }

    func testSummaryExpandCollapseChangesHeight() {
        let emptyJSON = """
        { "data": { "user_holding": [] }}
        """.data(using: .utf8)!

        MockURLProtocol.handler = { _ in
            (HTTPURLResponse(url: URL(string: "https://x")!,
                             statusCode: 200,
                             httpVersion: nil,
                             headerFields: nil)!,
             emptyJSON)
        }

        let vc = PortfolioViewController()
        vc.loadViewIfNeeded()

        guard let summary = find(vc.view, SummaryView.self),
              let button = find(summary, UIButton.self)
        else { XCTFail("Summary or button missing"); return }

        vc.view.layoutIfNeeded()
        let collapsed = summary.frame.height

        button.sendActions(for: .touchUpInside)
        waitUntil { summary.frame.height != collapsed }

        let expanded = summary.frame.height
        XCTAssertNotEqual(expanded, collapsed)

        button.sendActions(for: .touchUpInside)
        waitUntil { summary.frame.height == collapsed }
    }
}
