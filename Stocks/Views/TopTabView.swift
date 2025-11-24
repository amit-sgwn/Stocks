import UIKit

final class TopTabView: UIView {
    enum Tab { case positions, holdings }

    // public callback
    var onTabChanged: ((Tab) -> Void)?

    private let positionsButton = UIButton(type: .system)
    private let holdingsButton = UIButton(type: .system)
    private let indicator = UIView()
    private var indicatorLeading: NSLayoutConstraint!
    private(set) var selected: Tab = .holdings

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:)") }

    private func setup() {
        positionsButton.setTitle("POSITIONS", for: .normal)
        holdingsButton.setTitle("HOLDINGS", for: .normal)

        positionsButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        holdingsButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)

        positionsButton.setTitleColor(.secondaryLabel, for: .normal)
        holdingsButton.setTitleColor(.label, for: .normal)

        positionsButton.addTarget(self, action: #selector(tapPositions), for: .touchUpInside)
        holdingsButton.addTarget(self, action: #selector(tapHoldings), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [positionsButton, holdingsButton])
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false

        indicator.backgroundColor = .systemBlue
        indicator.layer.cornerRadius = 2
        indicator.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)
        addSubview(indicator)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.heightAnchor.constraint(equalToConstant: 44),

            indicator.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: 6),
            indicator.heightAnchor.constraint(equalToConstant: 3),
            indicator.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5, constant: -24)
        ])

        // initial leading
        indicatorLeading = indicator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16)
        indicatorLeading.isActive = true
    }

    @objc private func tapPositions() { select(.positions, animated: true) }
    @objc private func tapHoldings() { select(.holdings, animated: true) }

    func select(_ tab: Tab, animated: Bool) {
        guard tab != selected else { return }
        selected = tab

        positionsButton.setTitleColor(tab == .positions ? .label : .secondaryLabel, for: .normal)
        holdingsButton.setTitleColor(tab == .holdings ? .label : .secondaryLabel, for: .normal)

        let leading: CGFloat = tab == .positions ? 16 : (bounds.width / 2) + 16
        indicatorLeading.constant = leading

        if animated {
            UIView.animate(withDuration: 0.26, delay: 0, options: .curveEaseInOut) {
                self.layoutIfNeeded()
            }
        } else {
            layoutIfNeeded()
        }

        onTabChanged?(tab)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // ensure indicator position is correct after layout
        let leading: CGFloat = selected == .positions ? 16 : (bounds.width / 2) + 16
        indicatorLeading.constant = leading
    }
}