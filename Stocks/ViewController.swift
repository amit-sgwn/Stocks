//
//  ViewController.swift
//  Stocks
//
//  Created by Amit Kumar on 17/11/25.
//

import UIKit
import Combine

final class PortfolioViewController: UIViewController {

    private let tableView = UITableView()
    private let summaryView = SummaryView()
    private var summaryHeightConstraint: NSLayoutConstraint!

    private let collapsedHeight: CGFloat = 60
    private let expandedHeight: CGFloat = 180

    private var cancellables = Set<AnyCancellable>()
    private var viewModel = PortfolioViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        setupTable()
        setupSummary()
        bind()
        Task { await viewModel.load() }
    }

    private func setupTable() {
        tableView.dataSource = self
        tableView.register(HoldingCell.self, forCellReuseIdentifier: HoldingCell.reuseId)
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 72
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    private func setupSummary() {
        summaryView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(summaryView)

        summaryHeightConstraint = summaryView.heightAnchor.constraint(equalToConstant: collapsedHeight)

        NSLayoutConstraint.activate([
            summaryView.topAnchor.constraint(equalTo: tableView.bottomAnchor),
            summaryView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            summaryView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            summaryView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            summaryHeightConstraint
        ])
    }

    private func bind() {

        summaryView.onToggle = { [weak self] expanded in
            guard let self = self else { return }
            self.animateSummary(expanded)
        }

        viewModel.$holdings
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
                self?.updateSummary()
            }
            .store(in: &cancellables)
    }

    private func updateSummary() {
        summaryView.bind(
            current: viewModel.currentValue,
            investment: viewModel.totalInvestment,
            today: viewModel.todaysPNL,
            total: viewModel.totalPNL
        )
    }

    private func animateSummary(_ expand: Bool) {
        summaryHeightConstraint.constant = expand ? expandedHeight : collapsedHeight

        UIView.animate(withDuration: 0.25,
                       delay: 0,
                       options: [.curveEaseInOut],
                       animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
}

extension PortfolioViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { viewModel.holdings.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(withIdentifier: HoldingCell.reuseId, for: indexPath) as? HoldingCell else {
            return UITableViewCell()
        }
        let model = viewModel.holdings[indexPath.row]
        cell.configure(with: model)
        return cell
    }
}
