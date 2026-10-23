import XCTest
@testable import OrbitDropKit

final class ComplianceAuditTests: XCTestCase {
    func testZeroStoreKitOrPaymentClasses() {
        // Auditoria estrita em runtime: proíbe classes de compra da Apple
        XCTAssertNil(NSClassFromString("SKPaymentQueue"), "StoreKit SKPaymentQueue não deve existir nas dependências de compilação")
        XCTAssertNil(NSClassFromString("SKStoreProductViewController"), "StoreKit não pode estar presente no app")
    }

    func testZeroCommercialLimitingCountersInUserDefaults() {
        let defaults = UserDefaults.standard
        let allKeys = defaults.dictionaryRepresentation().keys

        let forbiddenKeywords = ["trialCount", "usageCount", "freeTierLimit", "licenseKey", "hasPurchased", "subscriptionActive"]
        for key in allKeys {
            for keyword in forbiddenKeywords {
                XCTAssertFalse(key.lowercased().contains(keyword.lowercased()), "Chave suspeita de controle comercial encontrada: \(key)")
            }
        }
    }

    func testAllTwentyFourPublicToolsMapped() {
        let expectedToolIDs: [String] = [
            "tool.compress", "tool.metadata", "tool.adjust", "tool.annotate",
            "tool.background", "tool.crop", "tool.redact", "tool.collage",
            "tool.video.trim", "tool.video.crop", "tool.video.speed", "tool.video.join",
            "tool.video.frames", "tool.video.split", "tool.video.redact",
            "tool.audio.normalize", "tool.audio.visualizer", "tool.audio.trim",
            "tool.audio.channels", "tool.audio.bleep",
            "tool.pdf.merge", "tool.pdf.split", "tool.pdf.organize",
            "tool.qr"
        ]

        XCTAssertEqual(expectedToolIDs.count, 24, "Devem haver exatamente 24 ferramentas públicas no catálogo")
        for id in expectedToolIDs {
            XCTAssertTrue(id.hasPrefix("tool."), "Todas as ferramentas devem possuir identificador unificado 'tool.*'")
        }
    }
}
