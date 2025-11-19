//
//  SummaryView.swift
//  Stocks
//
//  Created by Amit Kumar on 17/11/25.
//


// Views/SummaryView.swift
import UIKit

final class SummaryView: UIView {

    private let currentValueLabel = UILabel()
    private let totalInvestmentLabel = UILabel()
    private let todayPnlLabel = UILabel()
    private let totalPnlLabel = UILabel()

    private let detailsStack = UIStackView()
    private let pnlRow = UIStackView()
    private let toggleButton = UIButton(type: .system)

    var onToggle: ((Bool) -> Void)?
    private(set) var isExpanded = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        backgroundColor = UIColor.systemBackground
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.05
        layer.shadowRadius = 6

        // ----- DETAILS STACK -----
        detailsStack.axis = .vertical
        detailsStack.spacing = 8
        detailsStack.addArrangedSubview(row("Current value", currentValueLabel))
        detailsStack.addArrangedSubview(row("Total investment", totalInvestmentLabel))
        detailsStack.addArrangedSubview(row("Today's PNL", todayPnlLabel))

        // ----- PNL ROW -----
        let t = UILabel()
        t.text = "Profit & Loss"
        t.font = .systemFont(ofSize: 12)
        t.textColor = .secondaryLabel

        totalPnlLabel.font = .boldSystemFont(ofSize: 16)
        totalPnlLabel.textAlignment = .right
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        toggleButton.setImage(UIImage(systemName: "chevron.down", withConfiguration: config), for: .normal)
        toggleButton.tintColor = .gray
        
//        toggleButton.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        toggleButton.addTarget(self, action: #selector(toggle), for: .touchUpInside)
        
        let gap = UIView()
        gap.widthAnchor.constraint(equalToConstant: 12).isActive = true

        pnlRow.axis = .horizontal
        pnlRow.alignment = .center
        pnlRow.addArrangedSubview(t)
        pnlRow.addArrangedSubview(gap)
        pnlRow.addArrangedSubview(toggleButton)
        pnlRow.addArrangedSubview(UIView())
        pnlRow.addArrangedSubview(totalPnlLabel)

        // ----- CONTAINER -----
        let container = UIStackView(arrangedSubviews: [detailsStack, pnlRow])
        container.axis = .vertical
        container.spacing = 8
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            container.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            container.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
        ])

        // collapsed initially
        detailsStack.isHidden = true
    }

    private func row(_ title: String, _ label: UILabel) -> UIStackView {
        let t = UILabel()
        t.text = title
        t.font = .systemFont(ofSize: 12)
        t.textColor = .secondaryLabel

        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .right

        let h = UIStackView(arrangedSubviews: [t, UIView(), label])
        h.axis = .horizontal
        return h
    }

    func bind(current: Double, investment: Double, today: Double, total: Double) {
        currentValueLabel.text = "₹ \(current)"
        totalInvestmentLabel.text = "₹ \(investment)"
        todayPnlLabel.text = "₹ \(today)"
        totalPnlLabel.text = "₹ \(total)"
        let pnl = total
        let percent = investment == 0 ? 0 : (pnl / investment) * 100
        
        let formatted = String(format: "₹ %.2f (%.2f%%)", pnl, percent)
        totalPnlLabel.text = formatted
        totalPnlLabel.textColor = total >= 0 ? .systemGreen : .systemRed
    }

    @objc private func toggle() {
        setExpanded(!isExpanded, animated: true)
        onToggle?(isExpanded)
    }

    func setExpanded(_ expand: Bool, animated: Bool) {
        isExpanded = expand

        let transform = expand ? CGAffineTransform(rotationAngle: .pi) : .identity

        if animated {
            UIView.animate(withDuration: 0.25) {
                self.detailsStack.isHidden = !expand
                self.toggleButton.imageView?.transform = transform
            }
        } else {
            detailsStack.isHidden = !expand
            toggleButton.imageView?.transform = transform
        }
    }
}
