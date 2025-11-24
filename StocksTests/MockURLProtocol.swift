//
//  MockURLProtocol.swift
//  Stocks
//
//  Created by Amit Kumar on 20/11/25.
//


import XCTest
@testable import YourAppTargetName
import UIKit

/// A URLProtocol that allows tests to supply canned HTTP responses for any request.
final class MockURLProtocol: URLProtocol {
    /// Set by tests to provide response for an incoming request.
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        // Handle all requests
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            let err = NSError(domain: "MockURLProtocol", code: 0, userInfo: [NSLocalizedDescriptionKey: "No handler set"])
            client?.urlProtocol(self, didFailWithError: err)
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {
        // no-op
    }
}

final class PortfolioViewControllerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Register MockURLProtocol globally (URLSession.shared will pick it up).
        URLProtocol.registerClass(MockURLProtocol.self)
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        URLProtocol.unregisterClass(MockURLProtocol.self)
        super.tearDown()
    }

    // Helper: find first subview of given type in view tree
    private func findView<T: UIView>(in root: UIView, ofType type: T.Type) -> T? {
        if let v = root as? T { return v }
        for s in root.subviews {
            if let found = findView(in: s, ofType: type) { return found }
        }
        return nil
    }

    // Helper: poll until condition becomes true or timeout
    private func waitFor(timeout: TimeInterval = 2, condition: @escaping () -> Bool, completion: @escaping (Bool) -> Void) {
        let deadline = Date().addingTimeInterval(timeout)
        func poll() {
            if condition() {
                completion(true); return
            }
            if Date() > deadline {
                completion(false); return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { poll() }
        }
        DispatchQueue.main.async { poll() }
    }

    func testTableLoadsHoldings_fromMockNetwork() {
        // Prepare sample JSON that matches PortfolioResponse with snake_case
        let json = """
        {
          "data": {
            "user_holding": [
              { "symbol": "AAPL", "quantity": 2, "ltp": 150.0, "avg_price": 120.0, "close": 140.0 }
            ]
          }
        }
        """.data(using: .utf8)!

        // Handler replies with 200 and our JSON
        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(url: URL(string: "https://example")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, json)
        }

        // Instantiate VC (it will create viewModel and trigger load in viewDidLoad)
        let vc = PortfolioViewController()
        // load view on main thread
        DispatchQueue.main.sync { vc.loadViewIfNeeded() }

        // Find the table view in the VC
        guard let table = findView(in: vc.view, ofType: UITableView.self) else {
            XCTFail("UITableView not found in view hierarchy"); return
        }

        // Wait until the table reports 1 row (or fail after timeout)
        let exp = expectation(description: "table rows populated")
        waitFor(timeout: 3, condition: {
            return table.numberOfRows(inSection: 0) == 1
        }) { ok in
            XCTAssertTrue(ok, "Table did not populate in time. Rows: \(table.numberOfRows(inSection: 0))")
            if ok {
                // Optionally assert the first cell content
                let cell = table.dataSource?.tableView(table, cellForRowAt: IndexPath(row: 0, section: 0))
                XCTAssertNotNil(cell)
                // You can assert visible label text by traversing cell subviews if needed
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 4)
    }

    func testSwitchingTabs_updatesTableRows() {
        // Return one holding from API
        let json = """
        {
          "data": {
            "user_holding": [
              { "symbol": "A", "quantity": 1, "ltp": 100.0, "avg_price": 90.0, "close": 95.0 }
            ]
          }
        }
        """.data(using: .utf8)!

        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(url: URL(string: "https://example")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, json)
        }

        let vc = PortfolioViewController()
        DispatchQueue.main.sync { vc.loadViewIfNeeded() }

        guard let table = findView(in: vc.view, ofType: UITableView.self) else {
            XCTFail("UITableView not found"); return
        }
        guard let topTab = findView(in: vc.view, ofType: TopTabView.self) else {
            XCTFail("TopTabView not found"); return
        }

        // Wait for data to load
        let exp1 = expectation(description: "rows populated")
        waitFor(timeout: 3, condition: { table.numberOfRows(inSection: 0) == 1 }) { ok in
            XCTAssertTrue(ok)
            exp1.fulfill()
        }
        wait(for: [exp1], timeout: 4)

        // Tap/select positions tab (should show 0 rows)
        DispatchQueue.main.sync {
            topTab.select(.positions, animated: false)
        }
        XCTAssertEqual(table.numberOfRows(inSection: 0), 0, "Positions tab should show 0 rows (not implemented)")

        // Tap/select holdings tab (should show 1 row)
        DispatchQueue.main.sync {
            topTab.select(.holdings, animated: false)
        }
        XCTAssertEqual(table.numberOfRows(inSection: 0), 1, "Holdings tab should show rows from model")
    }

    func testSummaryToggle_resizesSummaryHeight() {
        // Sample JSON for 1 holding
        let json = """
        {
          "data": {
            "user_holding": [
              { "symbol": "A", "quantity": 1, "ltp": 100.0, "avg_price": 90.0, "close": 95.0 }
            ]
          }
        }
        """.data(using: .utf8)!

        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(url: URL(string: "https://example")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, json)
        }

        let vc = PortfolioViewController()
        DispatchQueue.main.sync { vc.loadViewIfNeeded() }

        // find summary view instance
        guard let summary = findView(in: vc.view, ofType: SummaryView.self) else {
            XCTFail("SummaryView not found"); return
        }

        // find the chevron/toggle button inside summary by searching UIButton
        func findButton(in view: UIView) -> UIButton? {
            if let b = view as? UIButton { return b }
            for s in view.subviews {
                if let b = findButton(in: s) { return b }
            }
            return nil
        }
        guard let toggle = findButton(in: summary) else {
            XCTFail("Toggle button not found in SummaryView"); return
        }

        // get summary initial height (frame may be zero until layout pass; force layout)
        DispatchQueue.main.sync {
            vc.view.setNeedsLayout()
            vc.view.layoutIfNeeded()
        }
        let initialHeight = summary.frame.height

        // Tap the toggle
        DispatchQueue.main.sync {
            toggle.sendActions(for: .touchUpInside)
        }

        // wait a moment for animation/layout
        let exp = expectation(description: "summary resized")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            vc.view.layoutIfNeeded()
            let newHeight = summary.frame.height
            XCTAssertNotEqual(initialHeight, newHeight, "Summary height should change after toggle (expand/collapse)")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
}