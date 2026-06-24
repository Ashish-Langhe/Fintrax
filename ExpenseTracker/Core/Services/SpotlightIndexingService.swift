//
//  SpotlightIndexingService.swift
//  Fintrax
//
//  Fintrax documentation: Indexes user-selected Fintrax destinations in Core Spotlight.
//

import CoreSpotlight
import Foundation
import UniformTypeIdentifiers

struct SpotlightIndexingService {
    static let enabledDestinationsKey = "spotlightEnabledDestinations"
    static let domainIdentifier = "com.fintrax.spotlight.destinations"
    static let activityIdentifierKey = CSSearchableItemActivityIdentifier

    private static let defaultDestinations: Set<FintraxSpotlightDestination> = [
        .dashboard,
        .expenses,
        .budget,
        .analytics,
        .reports,
        .income
    ]

    private let userDefaults: UserDefaults
    private let searchableIndex: CSSearchableIndex

    init(
        userDefaults: UserDefaults = .standard,
        searchableIndex: CSSearchableIndex = .default()
    ) {
        self.userDefaults = userDefaults
        self.searchableIndex = searchableIndex
    }

    func selectedDestinations() -> Set<FintraxSpotlightDestination> {
        guard userDefaults.object(forKey: Self.enabledDestinationsKey) != nil else {
            return Self.defaultDestinations
        }

        let rawValue = userDefaults.string(forKey: Self.enabledDestinationsKey) ?? ""
        let selected = rawValue
            .split(separator: ",")
            .compactMap { FintraxSpotlightDestination(rawValue: String($0)) }

        return Set(selected)
    }

    func isEnabled(_ destination: FintraxSpotlightDestination) -> Bool {
        selectedDestinations().contains(destination)
    }

    func setEnabled(_ enabled: Bool, for destination: FintraxSpotlightDestination) async {
        var selected = selectedDestinations()
        if enabled {
            selected.insert(destination)
        } else {
            selected.remove(destination)
        }

        save(selected)
        await reindexSelectedDestinations()
    }

    func reindexSelectedDestinations() async {
        await deleteIndexedDestinations()
        let items = selectedDestinations().map(searchableItem(for:))

        do {
            try await searchableIndex.indexSearchableItems(items)
        } catch {
            ErrorLogger.log(error, context: "SpotlightIndexingService.reindexSelectedDestinations")
        }
    }

    func deleteIndexedDestinations() async {
        do {
            try await searchableIndex.deleteSearchableItems(withDomainIdentifiers: [Self.domainIdentifier])
        } catch {
            ErrorLogger.log(error, context: "SpotlightIndexingService.deleteIndexedDestinations")
        }
    }

    func destination(for searchableIdentifier: String) -> FintraxSpotlightDestination? {
        guard searchableIdentifier.hasPrefix(Self.itemIdentifierPrefix) else { return nil }
        let rawValue = searchableIdentifier.replacingOccurrences(of: Self.itemIdentifierPrefix, with: "")
        return FintraxSpotlightDestination(rawValue: rawValue)
    }

    private func save(_ destinations: Set<FintraxSpotlightDestination>) {
        let rawValue = destinations
            .map(\.rawValue)
            .sorted()
            .joined(separator: ",")
        userDefaults.set(rawValue, forKey: Self.enabledDestinationsKey)
    }

    private func searchableItem(for destination: FintraxSpotlightDestination) -> CSSearchableItem {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .item)
        attributeSet.title = destination.localizedTitle
        attributeSet.contentDescription = destination.localizedSubtitle
        attributeSet.keywords = keywords(for: destination)
        attributeSet.displayName = destination.localizedTitle
        attributeSet.thumbnailData = nil

        return CSSearchableItem(
            uniqueIdentifier: Self.itemIdentifier(for: destination),
            domainIdentifier: Self.domainIdentifier,
            attributeSet: attributeSet
        )
    }

    private func keywords(for destination: FintraxSpotlightDestination) -> [String] {
        let common = ["Fintrax", destination.localizedTitle, destination.localizedSubtitle]

        switch destination {
        case .dashboard:
            return common + ["home", "summary", "money snapshot", "overview"]
        case .expenses:
            return common + ["expense list", "transactions", "month", "calendar"]
        case .analytics:
            return common + ["charts", "spending", "category", "insights"]
        case .budget:
            return common + ["budget", "available money", "income sync", "limit"]
        case .settings:
            return common + ["settings", "language", "theme", "security"]
        case .income:
            return common + ["income", "salary", "freelance", "refunds"]
        case .bills:
            return common + ["bills", "payment", "reminders", "emi", "subscriptions"]
        case .reports:
            return common + ["reports", "pdf", "csv", "export"]
        case .categories:
            return common + ["categories", "tags", "icons", "colors"]
        }
    }

    private static let itemIdentifierPrefix = "fintrax.spotlight.destination."

    private static func itemIdentifier(for destination: FintraxSpotlightDestination) -> String {
        "\(itemIdentifierPrefix)\(destination.rawValue)"
    }
}
