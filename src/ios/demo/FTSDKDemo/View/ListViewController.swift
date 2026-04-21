//
//  ListViewController.swift
//  FTSDKDemo
//
//  Created by hulilei on 2023/7/18.
//

import UIKit
import SDWebImage

class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private enum HomeEntry: Int, CaseIterable {
        case realScenario
        case technicalVerification

        var title: String {
            switch self {
            case .realScenario:
                return NSLocalizedString("real_scenario_entry_title", comment: "Real scenario entry title")
            case .technicalVerification:
                return NSLocalizedString("technical_verification_entry_title", comment: "Technical verification entry title")
            }
        }

        var detail: String {
            switch self {
            case .realScenario:
                return NSLocalizedString("real_scenario_entry_description", comment: "Real scenario entry description")
            case .technicalVerification:
                return NSLocalizedString("technical_verification_entry_description", comment: "Technical verification entry description")
            }
        }

        var iconName: String {
            switch self {
            case .realScenario:
                return "icon_real_scene"
            case .technicalVerification:
                return "icon_test_scene"
            }
        }
    }

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: view.bounds, style: .insetGrouped)
        table.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        table.delegate = self
        table.dataSource = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "listTableViewCell")
        table.rowHeight = 72
        return table
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("home", comment: "Home tab title")
        view.backgroundColor = .navigationBackgroundColor
        view.addSubview(tableView)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        HomeEntry.allCases.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        NSLocalizedString("home_scene_header", comment: "Home scene section header")
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        NSLocalizedString("home_scene_footer", comment: "Home scene section footer")
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "listTableViewCell")
        guard let entry = HomeEntry(rawValue: indexPath.row) else {
            return cell
        }

        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.text = entry.title
        cell.textLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        cell.detailTextLabel?.text = entry.detail
        cell.detailTextLabel?.font = .systemFont(ofSize: 13)
        cell.detailTextLabel?.numberOfLines = 2
        cell.imageView?.image = resizedIcon(named: entry.iconName)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let entry = HomeEntry(rawValue: indexPath.row) else {
            return
        }

        let destination: UIViewController
        switch entry {
        case .realScenario:
            destination = RealScenarioListViewController()
        case .technicalVerification:
            destination = TechnicalVerificationViewController()
        }

        hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(destination, animated: true)
        hidesBottomBarWhenPushed = false
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        tableView.reloadData()
    }

    private func resizedIcon(named name: String) -> UIImage? {
        guard let image = UIImage(named: name) else {
            return nil
        }
        let itemSize = CGSize(width: 40, height: 40)
        UIGraphicsBeginImageContextWithOptions(itemSize, false, UIScreen.main.scale)
        image.draw(in: CGRect(origin: .zero, size: itemSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resized
    }
}

private final class TechnicalVerificationViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private enum TechnicalEntry: Int, CaseIterable {
        case nativeDemo
        case webViewDemo

        var title: String {
            switch self {
            case .nativeDemo:
                return NSLocalizedString("technical_native_entry_title", comment: "Technical native entry title")
            case .webViewDemo:
                return NSLocalizedString("technical_webview_entry_title", comment: "Technical WebView entry title")
            }
        }

        var detail: String {
            switch self {
            case .nativeDemo:
                return NSLocalizedString("technical_native_entry_description", comment: "Technical native entry description")
            case .webViewDemo:
                return NSLocalizedString("technical_webview_entry_description", comment: "Technical WebView entry description")
            }
        }

        var iconName: String {
            switch self {
            case .nativeDemo:
                return "ic_ios"
            case .webViewDemo:
                return "ic_web"
            }
        }
    }

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: view.bounds, style: .insetGrouped)
        table.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        table.delegate = self
        table.dataSource = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "technicalTableViewCell")
        table.rowHeight = 72
        return table
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("technical_verification_entry_title", comment: "Technical verification title")
        view.backgroundColor = .navigationBackgroundColor
        view.addSubview(tableView)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        TechnicalEntry.allCases.count
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        NSLocalizedString("technical_verification_intro", comment: "Technical verification intro")
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "technicalTableViewCell")
        guard let entry = TechnicalEntry(rawValue: indexPath.row) else {
            return cell
        }
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.text = entry.title
        cell.textLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        cell.detailTextLabel?.text = entry.detail
        cell.detailTextLabel?.numberOfLines = 2
        cell.detailTextLabel?.font = .systemFont(ofSize: 13)
        cell.imageView?.image = resizedIcon(named: entry.iconName)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let entry = TechnicalEntry(rawValue: indexPath.row) else {
            return
        }

        let destination: UIViewController
        switch entry {
        case .nativeDemo:
            destination = NativeViewController()
        case .webViewDemo:
            destination = WebViewController()
        }

        navigationController?.pushViewController(destination, animated: true)
    }

    private func resizedIcon(named name: String) -> UIImage? {
        guard let image = UIImage(named: name) else {
            return nil
        }
        let itemSize = CGSize(width: 40, height: 40)
        UIGraphicsBeginImageContextWithOptions(itemSize, false, UIScreen.main.scale)
        image.draw(in: CGRect(origin: .zero, size: itemSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resized
    }
}

private final class RealScenarioListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private var products: [ProductSummary] = []
    private let refreshControl = UIRefreshControl()

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: view.bounds, style: .plain)
        table.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        table.delegate = self
        table.dataSource = self
        table.register(ProductListCell.self, forCellReuseIdentifier: ProductListCell.reuseIdentifier)
        table.rowHeight = 176
        table.tableFooterView = UIView()
        table.separatorStyle = .none
        table.backgroundColor = .systemGroupedBackground
        table.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 24, right: 0)
        return table
    }()

    private lazy var emptyLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 15)
        label.isHidden = true
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("real_scenario_entry_title", comment: "Real scenario title")
        view.backgroundColor = .systemGroupedBackground
        view.addSubview(tableView)
        view.addSubview(emptyLabel)
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            emptyLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24)
        ])

        refreshControl.addTarget(self, action: #selector(refreshProducts), for: .valueChanged)
        tableView.refreshControl = refreshControl
        loadProducts(showLoading: true)
    }

    @objc private func refreshProducts() {
        loadProducts(showLoading: false)
    }

    private func loadProducts(showLoading: Bool) {
        if showLoading {
            emptyLabel.isHidden = true
        }

        Task {
            do {
                let data = try await fetch(urlString: "\(NetworkEngine.shared.baseUrl)/api/products")
                let items = try JSONDecoder().decode([ProductSummary].self, from: data)
                await MainActor.run {
                    products = items
                    tableView.reloadData()
                    refreshControl.endRefreshing()
                    updateEmptyState(message: NSLocalizedString("real_scenario_empty_text", comment: "No product data"))
                }
            } catch {
                await MainActor.run {
                    products = []
                    tableView.reloadData()
                    refreshControl.endRefreshing()
                    let format = NSLocalizedString("real_scenario_load_failed", comment: "Real scenario load failed")
                    updateEmptyState(message: String(format: format, error.localizedDescription))
                }
            }
        }
    }

    private func updateEmptyState(message: String) {
        let hasData = !products.isEmpty
        emptyLabel.isHidden = hasData
        emptyLabel.text = hasData ? nil : message
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        products.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel()
        label.text = NSLocalizedString("product_feed_intro", comment: "Product feed intro")
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 13)

        let container = UIView()
        container.backgroundColor = .clear
        container.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])
        return container
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        64
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ProductListCell.reuseIdentifier,
            for: indexPath
        ) as? ProductListCell else {
            return UITableViewCell()
        }
        let product = products[indexPath.row]
        cell.configure(with: product)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let controller = RealScenarioDetailViewController(productID: products[indexPath.row].id)
        navigationController?.pushViewController(controller, animated: true)
    }
}

private final class ProductListCell: UITableViewCell {
    static let reuseIdentifier = "ProductListCell"

    private let cardView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 20
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.separator.withAlphaComponent(0.12).cgColor
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.08
        view.layer.shadowRadius = 18
        view.layer.shadowOffset = CGSize(width: 0, height: 8)
        return view
    }()

    private let productImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 16
        imageView.layer.masksToBounds = true
        return imageView
    }()

    private let badgeLabel = PaddedLabel()
    private let statusLabel = PaddedLabel()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 17, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 3
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        return label
    }()

    private let priceLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = UIColor(red: 0.8, green: 0.31, blue: 0.0, alpha: 1)
        return label
    }()

    private let ratingLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = UIColor(red: 0.06, green: 0.3, blue: 0.51, alpha: 1)
        label.textAlignment = .right
        return label
    }()

    private let pillRow: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        return stack
    }()

    private let textStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 10
        stack.alignment = .fill
        return stack
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        badgeLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        badgeLabel.textColor = UIColor(red: 0.06, green: 0.3, blue: 0.51, alpha: 1)
        badgeLabel.backgroundColor = UIColor(red: 0.93, green: 0.96, blue: 1.0, alpha: 1)
        badgeLabel.layer.cornerRadius = 12
        badgeLabel.layer.masksToBounds = true
        badgeLabel.contentInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)

        statusLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        statusLabel.textColor = UIColor(red: 0.12, green: 0.49, blue: 0.55, alpha: 1)
        statusLabel.backgroundColor = UIColor(red: 0.9, green: 0.97, blue: 0.98, alpha: 1)
        statusLabel.layer.cornerRadius = 12
        statusLabel.layer.masksToBounds = true
        statusLabel.contentInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)

        contentView.addSubview(cardView)
        cardView.addSubview(productImageView)
        cardView.addSubview(textStack)
        pillRow.addArrangedSubview(badgeLabel)
        pillRow.addArrangedSubview(statusLabel)
        pillRow.addArrangedSubview(UIView())
        textStack.addArrangedSubview(pillRow)
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)

        let priceRow = UIStackView(arrangedSubviews: [priceLabel, UIView(), ratingLabel])
        priceRow.axis = .horizontal
        priceRow.alignment = .center
        priceRow.spacing = 8
        textStack.addArrangedSubview(priceRow)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            textStack.leadingAnchor.constraint(equalTo: productImageView.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),
            textStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            textStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14),

            productImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            productImageView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            productImageView.widthAnchor.constraint(equalToConstant: 132),
            productImageView.heightAnchor.constraint(equalTo: productImageView.widthAnchor, multiplier: 2.0 / 3.0)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with product: ProductSummary) {
        titleLabel.text = product.title
        subtitleLabel.text = product.subtitle
        badgeLabel.text = product.tag
        statusLabel.text = product.stock
        priceLabel.text = product.price
        ratingLabel.text = "Rating \(product.rating)"
        productImageView.sd_setImage(with: URL(string: product.imageURL), placeholderImage: UIImage(named: "ic_ios"))
    }
}

private final class RealScenarioDetailViewController: UIViewController {
    private let productID: String

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let heroCard = UIView()
    private let imageView = UIImageView()
    private let tagLabel = PaddedLabel()
    private let stockLabel = PaddedLabel()
    private let ratingLabel = PaddedLabel()
    private let titleLabel = UILabel()
    private let priceLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let statusLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let highlightLabel = UILabel()
    private let webPointsLabel = UILabel()
    private let specsContainerView = UIView()
    private let specsLabel = UILabel()
    private let loadingView = UIActivityIndicatorView(style: .large)

    init(productID: String) {
        self.productID = productID
        super.init(nibName: nil, bundle: nil)
        self.hidesBottomBarWhenPushed = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        configureLayout()
        loadProductDetail()
    }

    private func configureLayout() {
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        stackView.axis = .vertical
        stackView.spacing = 18
        stackView.alignment = .fill
        scrollView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24)
        ])

        heroCard.backgroundColor = .systemBackground
        heroCard.layer.cornerRadius = 24
        heroCard.layer.masksToBounds = true
        heroCard.layer.shadowColor = UIColor.black.cgColor
        heroCard.layer.shadowOpacity = 0.08
        heroCard.layer.shadowRadius = 24
        heroCard.layer.shadowOffset = CGSize(width: 0, height: 12)

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 18
        imageView.heightAnchor.constraint(equalToConstant: 220).isActive = true

        configurePill(tagLabel, textColor: UIColor(red: 0.06, green: 0.3, blue: 0.51, alpha: 1), backgroundColor: UIColor(red: 0.93, green: 0.96, blue: 1.0, alpha: 1))
        configurePill(stockLabel, textColor: UIColor(red: 0.12, green: 0.49, blue: 0.55, alpha: 1), backgroundColor: UIColor(red: 0.9, green: 0.97, blue: 0.98, alpha: 1))
        configurePill(ratingLabel, textColor: UIColor(red: 0.5, green: 0.31, blue: 0.03, alpha: 1), backgroundColor: UIColor(red: 1.0, green: 0.95, blue: 0.89, alpha: 1))

        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.numberOfLines = 0

        priceLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        priceLabel.textColor = UIColor(red: 0.8, green: 0.31, blue: 0.0, alpha: 1)
        priceLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        priceLabel.setContentHuggingPriority(.required, for: .horizontal)

        subtitleLabel.font = .systemFont(ofSize: 15)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0

        statusLabel.font = .systemFont(ofSize: 13)
        statusLabel.textColor = .secondaryLabel
        statusLabel.numberOfLines = 2
        statusLabel.textAlignment = .right
        statusLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        statusLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        descriptionLabel.font = .systemFont(ofSize: 15)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textColor = .label

        highlightLabel.font = .systemFont(ofSize: 14)
        highlightLabel.numberOfLines = 0
        highlightLabel.textColor = .label

        webPointsLabel.font = .systemFont(ofSize: 14)
        webPointsLabel.numberOfLines = 0
        webPointsLabel.textColor = .label

        specsContainerView.backgroundColor = UIColor(red: 0.97, green: 0.98, blue: 0.99, alpha: 1)
        specsContainerView.layer.cornerRadius = 12
        specsContainerView.layer.masksToBounds = true

        specsLabel.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        specsLabel.numberOfLines = 0
        specsLabel.translatesAutoresizingMaskIntoConstraints = false
        specsContainerView.addSubview(specsLabel)
        NSLayoutConstraint.activate([
            specsLabel.topAnchor.constraint(equalTo: specsContainerView.topAnchor, constant: 12),
            specsLabel.leadingAnchor.constraint(equalTo: specsContainerView.leadingAnchor, constant: 12),
            specsLabel.trailingAnchor.constraint(equalTo: specsContainerView.trailingAnchor, constant: -12),
            specsLabel.bottomAnchor.constraint(equalTo: specsContainerView.bottomAnchor, constant: -12)
        ])

        let webButton = buildButton(titleKey: "product_open_webview", selector: #selector(handleOpenWebView))
        let actionStatusCard = buildInfoBox(text: NSLocalizedString("product_feed_intro", comment: "Product feed intro"))

        let actionStack = UIStackView(arrangedSubviews: [webButton, actionStatusCard])
        actionStack.axis = .vertical
        actionStack.spacing = 12

        let heroStack = UIStackView(arrangedSubviews: [
            buildPillRow(),
            titleLabel,
            subtitleLabel,
            imageView,
            buildPriceStatusRow()
        ])
        heroStack.axis = .vertical
        heroStack.spacing = 14
        heroStack.translatesAutoresizingMaskIntoConstraints = false
        heroCard.addSubview(heroStack)
        NSLayoutConstraint.activate([
            heroStack.topAnchor.constraint(equalTo: heroCard.topAnchor, constant: 18),
            heroStack.leadingAnchor.constraint(equalTo: heroCard.leadingAnchor, constant: 18),
            heroStack.trailingAnchor.constraint(equalTo: heroCard.trailingAnchor, constant: -18),
            heroStack.bottomAnchor.constraint(equalTo: heroCard.bottomAnchor, constant: -18)
        ])

        let overviewStack = UIStackView(arrangedSubviews: [descriptionLabel])
        overviewStack.axis = .vertical
        overviewStack.spacing = 12
        let overviewCard = wrapCard(title: "Overview", content: overviewStack)

        let highlightStack = UIStackView(arrangedSubviews: [highlightLabel])
        highlightStack.axis = .vertical
        highlightStack.spacing = 12
        let highlightsCard = wrapCard(title: "Highlights", content: highlightStack)

        let pointsStack = UIStackView(arrangedSubviews: [webPointsLabel])
        pointsStack.axis = .vertical
        pointsStack.spacing = 12
        let webPointsCard = wrapCard(title: "Demo Coverage", content: pointsStack)

        let specsCard = wrapCard(title: "Specifications", content: specsContainerView)
        let actionCard = wrapCard(title: "Actions", content: actionStack)

        [heroCard, overviewCard, highlightsCard, webPointsCard, specsCard, actionCard].forEach {
            stackView.addArrangedSubview($0)
        }

        view.addSubview(loadingView)
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func buildButton(titleKey: String, selector: Selector) -> UIButton {
        let button = UIButton(type: .system)
        let title = NSLocalizedString(titleKey, comment: "")
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.filled()
            config.cornerStyle = .large
            config.title = title
            config.baseBackgroundColor = UIColor(red: 0.06, green: 0.3, blue: 0.51, alpha: 1)
            config.baseForegroundColor = .white
            button.configuration = config
        } else {
            button.setTitle(title, for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.backgroundColor = UIColor(red: 0.06, green: 0.3, blue: 0.51, alpha: 1)
            button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
            button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
            button.layer.cornerRadius = 12
            button.layer.masksToBounds = true
        }
        button.addTarget(self, action: selector, for: .touchUpInside)
        return button
    }

    private func configurePill(_ label: PaddedLabel, textColor: UIColor, backgroundColor: UIColor) {
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = textColor
        label.backgroundColor = backgroundColor
        label.contentInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
        label.layer.cornerRadius = 12
        label.layer.masksToBounds = true
    }

    private func buildPillRow() -> UIStackView {
        let row = UIStackView(arrangedSubviews: [tagLabel, stockLabel, ratingLabel, UIView()])
        row.axis = .horizontal
        row.spacing = 8
        row.alignment = .center
        return row
    }

    private func buildPriceStatusRow() -> UIStackView {
        let row = UIStackView(arrangedSubviews: [priceLabel, UIView(), statusLabel])
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 12
        return row
    }

    private func wrapCard(title: String, content: UIView) -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .systemBackground
        card.layer.cornerRadius = 20
        card.layer.masksToBounds = true

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.text = title

        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(titleLabel)
        card.addSubview(content)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),

            content.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18)
        ])
        return card
    }

    private func buildInfoBox(text: String) -> UIView {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.text = text

        let container = UIView()
        container.backgroundColor = UIColor(red: 0.97, green: 0.98, blue: 0.99, alpha: 1)
        container.layer.cornerRadius = 14
        container.layer.masksToBounds = true
        container.translatesAutoresizingMaskIntoConstraints = false

        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])
        return container
    }

    private func loadProductDetail() {
        loadingView.startAnimating()
        Task {
            do {
                let data = try await fetch(urlString: "\(NetworkEngine.shared.baseUrl)/api/products/\(productID)")
                let detail = try JSONDecoder().decode(ProductDetail.self, from: data)
                await MainActor.run {
                    loadingView.stopAnimating()
                    bind(detail: detail)
                }
            } catch {
                await MainActor.run {
                    loadingView.stopAnimating()
                    let format = NSLocalizedString("real_scenario_load_failed", comment: "Real scenario load failed")
                    titleLabel.text = String(format: format, error.localizedDescription)
                }
            }
        }
    }

    private func bind(detail: ProductDetail) {
        title = detail.title
        imageView.sd_setImage(with: URL(string: detail.imageURL), placeholderImage: UIImage(named: "ic_ios"))
        tagLabel.text = detail.tag
        stockLabel.text = detail.stock
        ratingLabel.text = "Rating \(detail.rating)"
        titleLabel.text = detail.title
        priceLabel.text = detail.price
        subtitleLabel.text = detail.subtitle
        let currentUser = UserManager.shared().userInfo?.username ?? NSLocalizedString("default_product_user", comment: "Default product user")
        let statusFormat = NSLocalizedString("product_status_format", comment: "Product status")
        statusLabel.text = String(format: statusFormat, currentUser, detail.rating, detail.stock)
        descriptionLabel.text = detail.description
        highlightLabel.text = detail.highlights.joined(separator: "\n• ").prependBulletIfNeeded()
        webPointsLabel.text = detail.webPoints.joined(separator: "\n• ").prependBulletIfNeeded()
        specsLabel.text = detail.formattedSpecs
    }

    @objc private func handleOpenWebView() {
        let url = "\(NetworkEngine.shared.baseUrl)/product/\(productID)"
        navigationController?.pushViewController(
            WebViewController(
                title: NSLocalizedString("product_webview_title", comment: "Product WebView title"),
                website: url
            ),
            animated: true
        )
    }
}

private struct ProductSummary: Decodable {
    let id: String
    let title: String
    let subtitle: String
    let imageURL: String
    let price: String
    let rating: String
    let tag: String
    let stock: String

    enum CodingKeys: String, CodingKey {
        case id, title, subtitle, price, rating, tag, stock
        case imageURL = "image_url"
    }
}

private struct ProductDetail: Decodable {
    let id: String
    let title: String
    let subtitle: String
    let imageURL: String
    let price: String
    let rating: String
    let tag: String
    let stock: String
    let description: String
    let highlights: [String]
    let specs: [String: String]
    let webPoints: [String]

    enum CodingKeys: String, CodingKey {
        case id, title, subtitle, price, rating, tag, stock, description, highlights, specs
        case webPoints = "web_points"
        case imageURL = "image_url"
    }

    var formattedSpecs: String {
        let prefix = NSLocalizedString("product_specs_prefix", comment: "Product specs prefix")
        let lines = specs.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
        return "\(prefix)\n\(lines)"
    }
}

private func fetch(urlString: String) async throws -> Data {
    guard let url = URL(string: urlString) else {
        throw RequestError.urlError
    }

    var request = URLRequest(url: url)
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpMethod = "GET"
    let (data, response) = try await URLSession.shared.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse, (200 ..< 300).contains(httpResponse.statusCode) else {
        throw RequestError.netError
    }
    return data
}

private extension String {
    func prependBulletIfNeeded() -> String {
        guard !isEmpty else {
            return self
        }
        return "• \(self)"
    }
}

private final class PaddedLabel: UILabel {
    var contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInsets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + contentInsets.left + contentInsets.right,
            height: size.height + contentInsets.top + contentInsets.bottom
        )
    }
}
