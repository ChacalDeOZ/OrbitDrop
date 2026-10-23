import Foundation
import UniformTypeIdentifiers

public struct FileDescriptor: Sendable, Equatable, Hashable {
    public let url: URL
    public let displayName: String
    public let fileSize: Int64
    public let contentType: UTType
    public let isDirectory: Bool

    public init(
        url: URL,
        displayName: String? = nil,
        fileSize: Int64? = nil,
        contentType: UTType? = nil,
        isDirectory: Bool? = nil
    ) {
        self.url = url
        self.displayName = displayName ?? url.lastPathComponent

        let path = url.path
        let fm = FileManager.default
        var isDir: ObjCBool = false
        let exists = fm.fileExists(atPath: path, isDirectory: &isDir)

        self.isDirectory = isDirectory ?? (exists && isDir.boolValue)

        if let size = fileSize {
            self.fileSize = size
        } else if let attrs = try? fm.attributesOfItem(atPath: path),
                  let num = attrs[.size] as? NSNumber {
            self.fileSize = num.int64Value
        } else {
            self.fileSize = 0
        }

        if let type = contentType {
            self.contentType = type
        } else if let resolved = UTType(filenameExtension: url.pathExtension) {
            self.contentType = resolved
        } else {
            self.contentType = .data
        }
    }
}
