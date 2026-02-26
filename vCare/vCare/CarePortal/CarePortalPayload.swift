import CryptoKit
import Foundation

struct CarePortalPayload: Codable {
    var payloadVersion: Int
    var shareID: String
    var patientDisplayName: String
    var createdAt: Date
    var cipherText: String
    var nonce: String
    var tag: String
    var key: String

    func toTokenString() -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(self) else { return "" }
        let payload = Base64URL.encode(data)
        return "vcare://portal?payload=\(payload)"
    }

    static func decodeToken(_ token: String) -> CarePortalPayload? {
        let payloadString: String
        if token.contains("vcare://") {
            guard let url = URL(string: token),
                  let queryItem = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "payload" }),
                  let value = queryItem.value else { return nil }
            payloadString = value
        } else {
            payloadString = token
        }
        guard let data = Base64URL.decode(payloadString) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(CarePortalPayload.self, from: data)
    }
}

enum CarePortalCrypto {
    static func encrypt(snapshot: CareShareProfileDTO) -> CarePortalPayload? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let snapshotData = try? encoder.encode(snapshot) else { return nil }
        let key = SymmetricKey(size: .bits256)
        do {
            let sealed = try AES.GCM.seal(snapshotData, using: key)
            guard let combined = sealed.combined else { return nil }
            let nonce = Base64URL.encode(Data(sealed.nonce))
            let ciphertext = Base64URL.encode(sealed.ciphertext)
            let tag = Base64URL.encode(sealed.tag)
            return CarePortalPayload(payloadVersion: snapshot.payloadVersion,
                                     shareID: snapshot.shareID,
                                     patientDisplayName: snapshot.patientDisplayName,
                                     createdAt: snapshot.createdAt,
                                     cipherText: ciphertext,
                                     nonce: nonce,
                                     tag: tag,
                                     key: Base64URL.encode(Data(key.withUnsafeBytes { Data($0) })))
        } catch {
            return nil
        }
    }

    static func decrypt(payload: CarePortalPayload) -> CareShareProfileDTO? {
        guard let keyData = Base64URL.decode(payload.key) else { return nil }
        let symmetricKey = SymmetricKey(data: keyData)
        guard let nonceData = Base64URL.decode(payload.nonce),
              let cipherData = Base64URL.decode(payload.cipherText),
              let tagData = Base64URL.decode(payload.tag) else { return nil }
        do {
            let sealedBox = try AES.GCM.SealedBox(nonce: AES.GCM.Nonce(data: nonceData),
                                                  ciphertext: cipherData,
                                                  tag: tagData)
            let decrypted = try AES.GCM.open(sealedBox, using: symmetricKey)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(CareShareProfileDTO.self, from: decrypted)
        } catch {
            return nil
        }
    }
}
