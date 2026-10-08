import Foundation
import Security

let arguments = CommandLine.arguments
guard arguments.count == 3 else {
    FileHandle.standardError.write(Data("usage: export-developer-id.swift <output.p12> <password>\n".utf8))
    exit(2)
}
let wanted = "Developer ID Application: Jeremy Daughhetee (PCWH4GSLHZ)"
let query: [String: Any] = [
    kSecClass as String: kSecClassIdentity,
    kSecMatchLimit as String: kSecMatchLimitAll,
    kSecReturnRef as String: true,
]
var found: CFTypeRef?
guard SecItemCopyMatching(query as CFDictionary, &found) == errSecSuccess, let identities = found as? [SecIdentity] else {
    FileHandle.standardError.write(Data("no identities found\n".utf8))
    exit(1)
}
for identity in identities {
    var certificate: SecCertificate?
    SecIdentityCopyCertificate(identity, &certificate)
    guard let certificate, (SecCertificateCopySubjectSummary(certificate) as String?) == wanted else { continue }
    var parameters = SecItemImportExportKeyParameters()
    parameters.version = UInt32(SEC_KEY_IMPORT_EXPORT_PARAMS_VERSION)
    parameters.passphrase = Unmanaged.passUnretained(arguments[2] as CFString)
    var data: CFData?
    let status = SecItemExport(identity, .formatPKCS12, [], &parameters, &data)
    guard status == errSecSuccess, let data else {
        FileHandle.standardError.write(Data("export failed: \(status)\n".utf8))
        exit(1)
    }
    try (data as Data).write(to: URL(fileURLWithPath: arguments[1]))
    print("exported \(wanted)")
    exit(0)
}
FileHandle.standardError.write(Data("\(wanted) not found\n".utf8))
exit(1)
