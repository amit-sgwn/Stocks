//
//  HoldingCell.swift
//  Stocks
//
//  Created by Amit Kumar on 17/11/25.
//

// Views/HoldingCell.swift

import UIKit

final class HoldingCell: UITableViewCell {
    static let reuseId = "HoldingCell"

    // MARK: - UI Elements
    private let symbolLabel = UILabel()

    private let qtyTitleLabel = UILabel()
    private let qtyValueLabel = UILabel()

    private let ltpTitleLabel = UILabel()
    private let ltpValueLabel = UILabel()

    private let pnlTitleLabel = UILabel()
    private let pnlValueLabel = UILabel()

    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup UI
    private func setup() {

        // --------- FONTS ---------
        symbolLabel.font = .boldSystemFont(ofSize: 16)

        let smallFont: UIFont = .systemFont(ofSize: 11)
        let valueFont: UIFont = .systemFont(ofSize: 14)

        qtyTitleLabel.font = smallFont
        qtyTitleLabel.textColor = .secondaryLabel
        qtyValueLabel.font = valueFont

        ltpTitleLabel.font = smallFont
        ltpTitleLabel.textColor = .secondaryLabel
        ltpValueLabel.font = valueFont

        pnlTitleLabel.font = smallFont
        pnlTitleLabel.textColor = .secondaryLabel
        pnlValueLabel.font = valueFont

        // --------- LEFT STACK ---------
        let qtyStack = UIStackView(arrangedSubviews: [qtyTitleLabel, qtyValueLabel])
        qtyStack.axis = .horizontal
        qtyStack.spacing = 4

        let leftStack = UIStackView(arrangedSubviews: [symbolLabel, qtyStack])
        leftStack.axis = .vertical
        leftStack.alignment = .leading
        leftStack.spacing = 4

        // --------- RIGHT STACK ---------
        let ltpStack = UIStackView(arrangedSubviews: [ltpTitleLabel, ltpValueLabel])
        ltpStack.axis = .horizontal
        ltpStack.spacing = 4

        let pnlStack = UIStackView(arrangedSubviews: [pnlTitleLabel, pnlValueLabel])
        pnlStack.axis = .horizontal
        pnlStack.spacing = 4

        let rightStack = UIStackView(arrangedSubviews: [ltpStack, pnlStack])
        rightStack.axis = .vertical
        rightStack.alignment = .trailing
        rightStack.spacing = 4

        // --------- HORIZONTAL STACK ---------
        let hStack = UIStackView(arrangedSubviews: [leftStack, UIView(), rightStack])
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.spacing = 8

        contentView.addSubview(hStack)
        hStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            hStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            hStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            hStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            hStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    // MARK: - Configure
    func configure(with model: Holding) {
        symbolLabel.text = model.symbol

        qtyTitleLabel.text = "Qty:"
        qtyValueLabel.text = "\(model.quantity)"

        ltpTitleLabel.text = "LTP:"
        ltpValueLabel.text = String(format: "₹ %.2f", model.ltp)

        let pnl = (model.ltp - model.avgPrice) * Double(model.quantity)
        
        pnlTitleLabel.text = "P&L:"
        pnlValueLabel.text = String(format: "₹ %.2f", pnl)
        pnlValueLabel.textColor = pnl >= 0 ? .systemGreen : .systemRed
    }
}
