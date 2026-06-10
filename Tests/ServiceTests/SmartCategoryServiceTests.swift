//
//  SmartCategoryServiceTests.swift
//  Fintrax
//
//  Fintrax documentation: Verifies smart category suggestions for expense entry.
//

import XCTest
@testable import ExpenseTracker

final class SmartCategoryServiceTests: XCTestCase {
    private var service: SmartCategoryService!
    private var categories: [Category]!

    override func setUp() {
        super.setUp()
        service = SmartCategoryService()
        categories = [
            Category(name: "Food", iconName: "fork.knife", colorName: "orange", isDefault: true),
            Category(name: "Transportation", iconName: "car.fill", colorName: "blue", isDefault: true),
            Category(name: "Shopping", iconName: "bag.fill", colorName: "pink", isDefault: true),
            Category(name: "Utilities", iconName: "bolt.fill", colorName: "yellow", isDefault: true),
            Category(name: "Health", iconName: "heart.fill", colorName: "red", isDefault: true),
            Category(name: "Entertainment", iconName: "tv.fill", colorName: "purple", isDefault: true),
            Category(name: "Travel", iconName: "airplane", colorName: "cyan"),
            Category(name: "Other", iconName: "ellipsis.circle.fill", colorName: "gray", isDefault: true)
        ]
    }

    override func tearDown() {
        service = nil
        categories = nil
        super.tearDown()
    }

    func testSuggestsFoodForRestaurantTitle() {
        assertSuggestion(for: "Starbucks coffee with team", equals: "Food")
    }

    func testSuggestsFoodForSingleMerchantTitle() {
        assertSuggestion(for: "Zomato", equals: "Food")
    }

    func testSuggestsFoodForGroceryAndCafeTitles() {
        assertSuggestion(for: "BigBasket groceries", equals: "Food")
        assertSuggestion(for: "CCD coffee", equals: "Food")
    }

    func testSuggestsFoodForVegetablesAndStaples() {
        assertSuggestion(for: "Tomato onion potato", equals: "Food")
        assertSuggestion(for: "Rice dal atta", equals: "Food")
    }

    func testSuggestsFoodForFriendsMealTitles() {
        assertSuggestion(for: "Friends dinner", equals: "Food")
        assertSuggestion(for: "Birthday cake", equals: "Food")
    }

    func testSuggestsTransportationForRideTitle() {
        assertSuggestion(for: "Uber ride to office", equals: "Transportation")
    }

    func testSuggestsTransportationForSingleMerchantTitle() {
        assertSuggestion(for: "Uber", equals: "Transportation")
    }

    func testSuggestsTransportationForVehicleAndCommuteTitles() {
        assertSuggestion(for: "FASTag toll recharge", equals: "Transportation")
        assertSuggestion(for: "Petrol refill", equals: "Transportation")
    }

    func testSuggestsTransportationForFuelBrandsAndOfficeCommute() {
        assertSuggestion(for: "Indian Oil petrol pump", equals: "Transportation")
        assertSuggestion(for: "Office cab", equals: "Transportation")
    }

    func testSuggestsEntertainmentForSubscriptionTitle() {
        assertSuggestion(for: "Netflix monthly subscription", equals: "Entertainment")
    }

    func testSuggestsEntertainmentForSingleMerchantTitle() {
        assertSuggestion(for: "Netflix", equals: "Entertainment")
    }

    func testSuggestsEntertainmentForEventsAndGamingTitles() {
        assertSuggestion(for: "BookMyShow movie tickets", equals: "Entertainment")
        assertSuggestion(for: "Steam game purchase", equals: "Entertainment")
    }

    func testSuggestsEntertainmentForPartyAndFriendsTitles() {
        assertSuggestion(for: "Friends party", equals: "Entertainment")
        assertSuggestion(for: "Team outing bowling", equals: "Entertainment")
    }

    func testSuggestsUtilitiesForBillTitle() {
        assertSuggestion(for: "Electricity bill payment", equals: "Utilities")
    }

    func testSuggestsUtilitiesForSingleProviderTitle() {
        assertSuggestion(for: "Airtel", equals: "Utilities")
    }

    func testSuggestsUtilitiesForHomeAndBillTitles() {
        assertSuggestion(for: "Society maintenance", equals: "Utilities")
        assertSuggestion(for: "Tata Play recharge", equals: "Utilities")
    }

    func testSuggestsHealthForPharmacyTitle() {
        assertSuggestion(for: "Apollo pharmacy medicines", equals: "Health")
    }

    func testSuggestsHealthForDiagnosticsAndFitnessTitles() {
        assertSuggestion(for: "Lal PathLabs blood test", equals: "Health")
        assertSuggestion(for: "Cultfit gym membership", equals: "Health")
    }

    func testSuggestsShoppingForRetailTitle() {
        assertSuggestion(for: "Amazon shoes order", equals: "Shopping")
    }

    func testSuggestsShoppingForSingleRetailTitle() {
        assertSuggestion(for: "Myntra", equals: "Shopping")
    }

    func testSuggestsShoppingForElectronicsAndBeautyTitles() {
        assertSuggestion(for: "Croma headphones", equals: "Shopping")
        assertSuggestion(for: "Nykaa cosmetics", equals: "Shopping")
    }

    func testSuggestsShoppingForDailyNeedsAndOfficeSupplies() {
        assertSuggestion(for: "Soap shampoo detergent", equals: "Shopping")
        assertSuggestion(for: "Office supplies notebook", equals: "Shopping")
    }

    func testSuggestsTravelForFlightTitle() {
        assertSuggestion(for: "Indigo flight ticket", equals: "Travel")
    }

    func testSuggestsTravelForHotelAndTripTitles() {
        assertSuggestion(for: "MakeMyTrip hotel booking", equals: "Travel")
        assertSuggestion(for: "RedBus bus ticket", equals: "Travel")
    }

    func testSuggestsEducationForCourseAndFeeTitles() {
        assertSuggestion(for: "Udemy course", equals: "Education")
        assertSuggestion(for: "School fees", equals: "Education")
    }

    func testUsesCustomCategoryNameAsSignal() {
        categories.append(Category(name: "Pets", iconName: "pawprint.fill", colorName: "brown"))

        assertSuggestion(for: "Pets grooming appointment", equals: "Pets")
    }

    func testReturnsNilForWeakUnknownTitle() {
        let suggestion = service.suggestCategory(for: "Project Alpha", categories: categories)

        XCTAssertNil(suggestion)
    }

    func testReturnsNilForEmptyInput() {
        let suggestion = service.suggestCategory(for: "  ", categories: categories)

        XCTAssertNil(suggestion)
    }

    private func assertSuggestion(
        for title: String,
        equals expectedCategoryName: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let suggestion = service.suggestCategory(for: title, categories: categories)

        XCTAssertEqual(suggestion?.category.name, expectedCategoryName, file: file, line: line)
        XCTAssertGreaterThanOrEqual(suggestion?.confidence ?? 0, 0.58, file: file, line: line)
    }
}
