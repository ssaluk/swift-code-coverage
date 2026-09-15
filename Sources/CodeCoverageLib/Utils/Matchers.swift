import Foundation

protocol Matcher {
    func callAsFunction(_ text: String) -> Bool
}

enum MatcherError: LocalizedError {
    case invalidExpression(String, Error)

    var errorDescription: String? {
        switch self {
        case let .invalidExpression(expression, error):
            "Invalid regular expression '\(expression)': \(error.localizedDescription)"
        }
    }
}

struct MatchAlways: Matcher {
    func callAsFunction(_ text: String) -> Bool {
        true
    }
}

struct MatchNever: Matcher {
    func callAsFunction(_ text: String) -> Bool {
        false
    }
}

struct ElementsMatcher: Matcher {
    var expressions: [NSRegularExpression]

    init(elements: [String]) throws {
        expressions = try elements.map { expression in
            do {
                return try NSRegularExpression(pattern: expression)
            } catch {
                throw MatcherError.invalidExpression(expression, error)
            }
        }
    }

    func callAsFunction(_ text: String) -> Bool {
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return expressions.first(where: {
            $0.rangeOfFirstMatch(in: text, range: range).location != NSNotFound
        }) != nil
    }
}
