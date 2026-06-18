//
//  SmartCategoryService.swift
//  Fintrax
//
//  Fintrax documentation: Provides local smart category suggestions for expense entry.
//

import Foundation

struct SmartCategorySuggestion: Equatable, Sendable {
    let category: Category
    let confidence: Double
    let matchedTerms: [String]

    var confidenceLabel: String {
        switch confidence {
        case 0.82...:
            return L10n.string("High confidence")
        case 0.66..<0.82:
            return L10n.string("Good match")
        default:
            return L10n.string("Suggested")
        }
    }
}

struct SmartCategoryService: Sendable {
    private let minimumConfidence: Double

    init(minimumConfidence: Double = 0.54) {
        self.minimumConfidence = minimumConfidence
    }

    func suggestCategory(for title: String, categories: [Category]) -> SmartCategorySuggestion? {
        let normalizedTitle = Self.normalized(title)
        guard normalizedTitle.count >= 3, !categories.isEmpty else { return nil }

        let scoredSuggestions = categories.compactMap { category -> SmartCategorySuggestion? in
            let result = score(category: category, normalizedTitle: normalizedTitle)
            guard result.score > 0 else { return nil }

            return SmartCategorySuggestion(
                category: category,
                confidence: min(result.score, 0.98),
                matchedTerms: result.matchedTerms
            )
        }
        .sorted { lhs, rhs in
            if lhs.confidence == rhs.confidence {
                return lhs.category.name < rhs.category.name
            }
            return lhs.confidence > rhs.confidence
        }

        guard let best = scoredSuggestions.first, best.confidence >= minimumConfidence else {
            return nil
        }

        if scoredSuggestions.count > 1 {
            let runnerUp = scoredSuggestions[1]
            guard best.confidence - runnerUp.confidence >= 0.08 else { return nil }
        }

        return best
    }

    private func score(category: Category, normalizedTitle: String) -> (score: Double, matchedTerms: [String]) {
        let categoryName = Self.normalized(category.name)
        var score = 0.0
        var matchedTerms: [String] = []

        if Self.containsTerm(categoryName, in: normalizedTitle) {
            score += 0.84
            matchedTerms.append(category.name)
        }

        for token in categoryName.split(separator: " ").map(String.init) where token.count > 2 {
            if Self.containsTerm(token, in: normalizedTitle) {
                score += 0.22
                matchedTerms.append(token)
            }
        }

        let canonicalName = Self.canonicalName(for: categoryName)
        let keywords = Self.categoryKeywords[canonicalName] ?? []

        for keyword in keywords {
            if Self.containsTerm(keyword, in: normalizedTitle) {
                score += keyword.contains(" ") ? 0.64 : 0.56
                matchedTerms.append(keyword)
            }
        }

        let uniqueMatches = Array(Set(matchedTerms)).sorted()
        let matchBonus = min(Double(uniqueMatches.count) * 0.06, 0.18)
        return (min(score + matchBonus, 0.98), uniqueMatches)
    }

    private static func containsTerm(_ term: String, in normalizedTitle: String) -> Bool {
        guard !term.isEmpty else { return false }
        let paddedTitle = " \(normalizedTitle) "
        return paddedTitle.contains(" \(term) ")
    }

    private static func normalized(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private static func canonicalName(for categoryName: String) -> String {
        switch categoryName {
        case "transport", "transportation", "commute", "fuel", "vehicle", "mobility":
            return "transportation"
        case "food", "dining", "groceries", "grocery", "restaurant", "restaurants":
            return "food"
        case "entertainment", "subscriptions", "subscription", "streaming", "movies":
            return "entertainment"
        case "utility", "utilities", "bills", "household", "home":
            return "utilities"
        case "health", "medical", "fitness", "wellness", "doctor":
            return "health"
        case "shopping", "shop", "retail", "clothing":
            return "shopping"
        case "travel", "trips", "trip", "vacation", "holiday":
            return "travel"
        case "education", "learning", "study", "books":
            return "education"
        default:
            return categoryName
        }
    }

    private static let categoryKeywords: [String: [String]] = [
        "food": [
            "restaurant", "restaurants", "dining", "dinner", "lunch", "breakfast", "brunch",
            "cafe", "coffee", "tea", "chai", "juice", "smoothie", "snack", "snacks", "meal",
            "meals", "takeaway", "delivery", "canteen", "bakery", "sweet", "sweets", "ice cream",
            "food", "food court", "office lunch", "team lunch", "friends dinner", "family dinner",
            "party snacks", "party food", "birthday cake", "cake", "pastry", "dessert", "biryani",
            "dosa", "idli", "vada", "poha", "upma", "paratha", "roti", "chapati", "naan", "rice",
            "dal", "pulses", "atta", "flour", "sugar", "salt", "oil", "ghee", "butter", "cheese",
            "paneer", "curd", "yogurt", "eggs", "egg", "chicken", "mutton", "fish", "seafood",
            "starbucks", "swiggy", "zomato", "blinkit", "zepto", "bigbasket", "instamart",
            "grofers", "dunzo", "dmart", "reliance fresh", "nature basket", "more supermarket",
            "spencer", "grocery", "groceries", "supermarket", "mart", "kirana", "milk", "bread",
            "vegetable", "vegetables", "veggies", "fruit", "fruits", "apple", "banana", "mango",
            "orange", "grapes", "watermelon", "papaya", "tomato", "tomatoes", "potato", "potatoes",
            "onion", "onions", "garlic", "ginger", "coriander", "mint", "spinach", "palak",
            "cauliflower", "cabbage", "carrot", "beans", "peas", "capsicum", "brinjal", "eggplant",
            "okra", "bhindi", "cucumber", "lemon", "chilli", "chilies", "broccoli", "mushroom",
            "dominos", "pizza hut", "mcdonald", "mcdonalds", "burger king",
            "kfc", "subway", "barista", "ccd", "costa", "haldiram", "bikanervala", "barbeque nation"
        ],
        "transportation": [
            "uber", "ola", "rapido", "taxi", "cab", "auto", "rickshaw", "metro", "bus", "train",
            "local train", "railway", "irctc", "fuel", "petrol", "diesel", "cng", "ev charging",
            "charging", "fuel station", "petrol pump", "gas station", "indian oil", "iocl",
            "bharat petroleum", "bpcl", "hindustan petroleum", "hp petrol", "hpcl", "shell",
            "reliance petrol", "nayara", "lubricant", "engine oil", "air pressure", "puncture",
            "parking", "toll", "fastag", "commute", "office commute", "office cab", "ride", "driver", "car wash",
            "service center", "vehicle service", "tyre", "tire", "mechanic", "garage", "bike",
            "scooter", "car", "transport", "transportation"
        ],
        "entertainment": [
            "netflix", "prime", "amazon prime", "prime video", "spotify", "apple music", "gaana",
            "wynk", "jiosaavn", "movie", "movies", "cinema", "pvr", "inox", "bookmyshow",
            "theatre", "concert", "event", "festival", "game", "games", "gaming", "playstation",
            "xbox", "steam", "nintendo", "subscription", "subscriptions", "hotstar", "disney",
            "youtube", "youtube premium", "music", "show", "shows", "ott", "zee5", "sonyliv",
            "jiocinema", "aha", "audible", "kindle unlimited", "party", "parties", "birthday party",
            "friends party", "office party", "team outing", "outing", "club", "pub", "bar", "lounge",
            "bowling", "arcade", "karaoke", "standup", "stand up", "comedy", "picnic"
        ],
        "utilities": [
            "electricity", "water", "gas", "wifi", "internet", "broadband", "phone", "mobile",
            "recharge", "dth", "bill", "bills", "utility", "maintenance", "rent", "society",
            "broadband", "airtel", "jio", "vi", "vodafone", "idea", "bsnl", "tata play",
            "dish tv", "sun direct", "hathway", "act fibernet", "excitel", "you broadband",
            "mseb", "mahavitaran", "bescom", "tneb", "adani electricity", "torrent power",
            "cylinder", "lpg", "png", "maid", "cleaning", "laundry", "dry cleaning", "house rent",
            "home rent", "society maintenance", "apartment", "bmc", "property tax"
        ],
        "health": [
            "pharmacy", "medical", "medicine", "medicines", "doctor", "hospital", "clinic",
            "dental", "dentist", "apollo", "apollo pharmacy", "netmeds", "pharmeasy", "tata 1mg",
            "1mg", "health", "healthcare", "fitness", "gym", "cult", "cultfit", "fitpass",
            "diagnostic", "diagnostics", "lab", "pathology", "thyrocare", "lal pathlabs",
            "metropolis", "scan", "xray", "mri", "ct scan", "blood test", "consultation",
            "therapy", "physio", "physiotherapy", "insurance", "health insurance", "vaccination",
            "vaccine", "spectacles", "lenskart", "lens", "eyecare", "wellness"
        ],
        "shopping": [
            "amazon", "flipkart", "myntra", "ajio", "nykaa", "meesho", "snapdeal", "tatacliq",
            "croma", "reliance digital", "vijay sales", "mall", "clothes", "clothing", "shirt",
            "jeans", "dress", "saree", "shoes", "footwear", "electronics", "mobile phone",
            "laptop", "headphones", "earphones", "charger", "accessories", "purchase", "order",
            "store", "market", "fashion", "zara", "hm", "h m", "max", "pantaloons", "lifestyle",
            "westside", "shoppers stop", "ikea", "home centre", "furniture", "appliance",
            "decathlon", "sports", "gift", "gifts", "cosmetics", "makeup", "beauty",
            "daily needs", "daily essentials", "essentials", "household items", "toiletries",
            "soap", "shampoo", "conditioner", "toothpaste", "toothbrush", "detergent",
            "dishwash", "dish wash", "cleaner", "floor cleaner", "phenyl", "handwash",
            "sanitizer", "tissue", "napkin", "diapers", "baby wipes", "razor", "deodorant",
            "office supplies", "office chair", "desk", "keyboard", "mouse", "printer",
            "stationery", "pen", "notebook", "paper", "file", "folder"
        ],
        "travel": [
            "flight", "flights", "hotel", "hotels", "airport", "indigo", "vistara", "air india",
            "akasa", "spicejet", "goibibo", "makemytrip", "cleartrip", "yatra", "airbnb",
            "booking", "booking com", "agoda", "trivago", "trip", "travel", "vacation",
            "holiday", "stay", "resort", "hostel", "homestay", "train ticket", "bus ticket",
            "redbus", "abhibus", "visa", "passport", "forex", "luggage", "tour", "tourism",
            "uber intercity", "rental car", "zoomcar"
        ],
        "education": [
            "course", "courses", "tuition", "school", "college", "university", "fees",
            "school fees", "college fees", "udemy", "coursera", "skillshare", "edx", "upgrad",
            "byjus", "unacademy", "vedantu", "exam", "exams", "class", "classes", "book",
            "books", "textbook", "notebook", "stationery", "learning", "workshop", "seminar",
            "certification", "certificate", "coaching", "training", "library", "kindle book"
        ]
    ]
}
