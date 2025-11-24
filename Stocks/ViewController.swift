//
//  PortfolioViewController.swift
//  Stocks
//
//  Created by Amit Kumar on 17/11/25.
//

import UIKit
import Combine

// MARK: - Tabs

enum PortfolioTab {
    case positions
    case holdings
}

final class PortfolioViewController: UIViewController {

    // MARK: - UI
    private let topTabs = TopTabView()            // use your existing TopTabView.swift
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let summaryView = SummaryView()       // your existing SummaryView

    // summary height constraint (collapsed / expanded)
    private var summaryHeightConstraint: NSLayoutConstraint!
    private let collapsedHeight: CGFloat = 60
    private let expandedHeight: CGFloat = 180

    // MARK: - State
    private var selectedTab: PortfolioTab = .holdings
    private var cancellables = Set<AnyCancellable>()
    private var viewModel = PortfolioViewModel()  // uses your existing VM

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Portfolio"
        view.backgroundColor = .systemBackground

        setupTabs()
        setupTable()
        setupSummary()
        bind()

        Task { await viewModel.load() }
    }

    // MARK: - Setup UI

    private func setupTabs() {
        topTabs.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topTabs)

        NSLayoutConstraint.activate([
            topTabs.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topTabs.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topTabs.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topTabs.heightAnchor.constraint(equalToConstant: 54)
        ])

        // When user taps tabs, update local state and reload table
        topTabs.onTabChanged = { [weak self] tab in
            guard let self = self else { return }
            switch tab {
            case .positions: self.selectedTab = .positions
            case .holdings:  self.selectedTab = .holdings
            }
            self.tableView.reloadData()
        }
    }

    private func setupTable() {
        // register cell
        tableView.register(HoldingCell.self, forCellReuseIdentifier: HoldingCell.reuseId)

        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 72
        tableView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: topTabs.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            // bottom anchor will be set in setupSummary() to summaryView.topAnchor
        ])
    }

    private func setupSummary() {
        summaryView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(summaryView)

        summaryHeightConstraint = summaryView.heightAnchor.constraint(equalToConstant: collapsedHeight)

        NSLayoutConstraint.activate([
            summaryView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            summaryView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            summaryView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            summaryHeightConstraint,
            // make table bottom attach to top of summary
            tableView.bottomAnchor.constraint(equalTo: summaryView.topAnchor)
        ])

        // collapsed initially
        summaryView.setExpanded(false, animated: false)

        // propagate toggle to animate height
        summaryView.onToggle = { [weak self] expanded in
            guard let self = self else { return }
            self.animateSummary(expand: expanded)
        }
    }

    // MARK: - Bindings

    private func bind() {
        // update table + summary when holdings change
        viewModel.$holdings
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.tableView.reloadData()
                self.updateSummary()
            }
            .store(in: &cancellables)

        // handle viewModel states (error handling)
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self else { return }
                self.handleState(state)
            }
            .store(in: &cancellables)
    }

    // MARK: - Helpers

    private func updateSummary() {
        summaryView.bind(
            current: viewModel.currentValue,
            investment: viewModel.totalInvestment,
            today: viewModel.todaysPNL,
            total: viewModel.totalPNL
        )
    }

    private func handleState(_ state: PortfolioViewModel.State) {
        switch state {
        case .idle:
            break
        case .loading:
            // optionally show a loading indicator
            break
        case .loaded:
            // already handled by holdings sink
            break
        case .error(let err):
            presentError(err)
        }
    }

    private func presentError(_ error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Summary animation

    private func animateSummary(expand: Bool) {
        // update summary internal UI immediately
        summaryView.setExpanded(expand, animated: true)

        // animate height
        summaryHeightConstraint.constant = expand ? expandedHeight : collapsedHeight

        UIView.animate(withDuration: 0.25,
                       delay: 0,
                       options: [.curveEaseInOut],
                       animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
}

// MARK: - UITableViewDataSource

extension PortfolioViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch selectedTab {
        case .positions:
            // positions not implemented yet — return 0
            return 0
        case .holdings:
            return viewModel.holdings.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        switch selectedTab {
        case .positions:
            // temporary placeholder cell until you add a Position model & cell
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "positionCell")
            cell.textLabel?.text = "Positions not implemented"
            cell.textLabel?.textColor = .secondaryLabel
            return cell

        case .holdings:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: HoldingCell.reuseId, for: indexPath) as? HoldingCell else {
                return UITableViewCell()
            }
            let model = viewModel.holdings[indexPath.row]
            cell.configure(with: model)
            return cell
        }
    }
}
