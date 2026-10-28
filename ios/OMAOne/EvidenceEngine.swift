import CryptoKit
import Foundation
import JavaScriptCore

/// Runs the same deterministic demo rules as proof-engine.ts in one local JS context.
@MainActor final class EvidenceEngine {
    static let shared = EvidenceEngine()
    private let context = JSContext()
    private(set) var loadError: String?

    private init() {
        guard let context, let url = Bundle.main.url(forResource:"evidence-engine",withExtension:"js"),
              let source = try? String(contentsOf:url,encoding:.utf8) else {
            loadError = "Локальный движок не найден"
            return
        }
        let sha256: @convention(block) (String) -> String = { value in
            SHA256.hash(data:Data(value.utf8)).map { String(format:"%02x",$0) }.joined()
        }
        context.setObject(sha256,forKeyedSubscript:"__sha256" as NSString)
        context.exceptionHandler = { [weak self] _, exception in
            self?.loadError = exception?.toString() ?? "Ошибка расчёта"
        }
        context.evaluateScript(source)
    }

    func run(_ module:String,input:[String:Any]? = nil) -> [String:Any]? {
        guard let context, loadError == nil else { return nil }
        let json = input.flatMap { try? JSONSerialization.data(withJSONObject:$0) }
            .flatMap { String(data:$0,encoding:.utf8) }
        guard let result = context.objectForKeyedSubscript("omaRun")?.call(withArguments:[module,json ?? ""])?.toString(),
              let data = result.data(using:.utf8),
              let object = try? JSONSerialization.jsonObject(with:data) as? [String:Any] else { return nil }
        return object
    }

    func toggleShelfStep(_ completed:[String],stepID:String) -> [String]? {
        guard let context, loadError == nil,
              let data = try? JSONSerialization.data(withJSONObject:completed),
              let json = String(data:data,encoding:.utf8),
              let result = context.objectForKeyedSubscript("omaShelfToggle")?
                .call(withArguments:[json,stepID])?.toString(),
              let resultData = result.data(using:.utf8),
              let ids = try? JSONSerialization.jsonObject(with:resultData) as? [String] else { return nil }
        return ids
    }
}


@MainActor
extension EvidenceEngine {
    func canCompleteShelfStep(
        _ completed: [String],
        stepID: String
    ) -> Bool {
        if completed.contains(stepID) {
            return true
        }

        guard let updated = toggleShelfStep(
            completed,
            stepID: stepID
        ) else {
            return false
        }

        return updated.contains(stepID)
    }
}
