import Foundation

/// Content safety & moderation engine for Quesly.
/// Filters hate speech, racism, xenophobia, nationalism, violence, harassment, and severe profanity.
/// Operates on-device in real-time before submission, compliant with Apple App Store Guideline 1.2 (UGC).
enum ContentModeration {
    
    enum ViolationCategory: String, CaseIterable {
        case hateSpeech = "Hate Speech & Discrimination"
        case harassment = "Harassment & Toxicity"
        case violence = "Violence & Harm"
    }

    struct ModerationResult {
        let isPermitted: Bool
        let violationCategory: ViolationCategory?
        let userMessage: String?
        
        static let clean = ModerationResult(isPermitted: true, violationCategory: nil, userMessage: nil)
        
        static func blocked(category: ViolationCategory, reason: String) -> ModerationResult {
            ModerationResult(isPermitted: false, violationCategory: category, userMessage: reason)
        }
    }

    // MARK: - Filter Patterns (Multi-language: English, Russian, Universal)

    /// Slurs, racial/ethnic disparagement, white supremacy, xenophobia, antisemitism, dehumanizing slurs.
    private static let hateAndRacismPatterns: [String] = [
        // English ethnic & racial slurs / hate phrases
        @"\b(nigg(a|er|az|uh)|chink|spic|kike|gook|wetback|coon|raghead|towelhead)\b",
        @"\b(white\s*power|white\s*supremac|kill\s*all\s*(blacks?|whites?|jews?|muslims?|gays?))\b",
        @"\b(hitler\s*was\s*right|gas\s*the\s*jews?|death\s*to\s*(jews?|blacks?|gays?|arabs?))\b",
        @"\b(subhuman|inferior\s*race|racial\s*purity|ethnic\s*cleansing)\b",
        @"\b(faggot|fag|dyke|tranny)\b",
        
        // Russian & Eastern European ethnic slurs, xenophobia & aggressive chauvinism
        @"(хач|хачик|хачи|чурк|чурка|чурки|чуркам|чурками)",
        @"(черномаз|чернож[оo]п|узкоглаз)",
        @"(жид|жидяр|жидовск|жидов|пархат)",
        @"(хох(ол|лы|лов)|укроп|укронацист|москал|кацап|бульбаш)",
        @"(чучмек|мамбет|пидор|пидорас|педик)",
        @"(россия\s*для\s*русских|бей\s*(жидов|чурок|хачей|хохлов|негров))",
        @"(смерть\s*(хохлам|москалям|жидам|чуркам|хачам|неграм))",
        @"(чурки\s*вон|очистим\s*нацию|недочеловек|недолюди)"
    ]

    /// Explicit violent incitement, physical harm, terror promotion
    private static let violencePatterns: [String] = [
        @"\b(i\s*will\s*kill\s*you|kill\s*yourself|go\s*die|mass\s*shoot)\b",
        @"(я\s*тебя\s*(убью|зарежу|прикончу)|сдохни|убей\s*себя|повеситься|вскрыть\s*вены)"
    ]

    // MARK: - Validation API

    /// Validates text against all safety rules. Returns clean result or user-friendly violation message.
    static func validate(_ text: String) -> ModerationResult {
        let normalized = text
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .replacingOccurrences(of: "@", with: "a")
            .replacingOccurrences(of: "$", with: "s")
            .replacingOccurrences(of: "1", with: "i")
            .replacingOccurrences(of: "0", with: "o")
            .replacingOccurrences(of: "3", with: "e")

        // 1. Check Hate Speech & Racism
        for pattern in hateAndRacismPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let range = NSRange(location: 0, length: normalized.utf16.count)
                if regex.firstMatch(in: normalized, options: [], range: range) != nil {
                    return .blocked(
                        category: .hateSpeech,
                        reason: "Quesly is a welcoming space. Remarks containing hate speech, racism, or discrimination are not permitted."
                    )
                }
            }
        }

        // 2. Check Violence & Threats
        for pattern in violencePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let range = NSRange(location: 0, length: normalized.utf16.count)
                if regex.firstMatch(in: normalized, options: [], range: range) != nil {
                    return .blocked(
                        category: .violence,
                        reason: "Responses containing threats, violence, or self-harm incitement violate our community guidelines."
                    )
                }
            }
        }

        return .clean
    }
}
