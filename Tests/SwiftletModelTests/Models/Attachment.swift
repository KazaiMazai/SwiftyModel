//
//  File.swift
//  
//
//  Created by Sergey Kazakov on 03/03/2024.
//

@testable import SwiftletModel
import Foundation

extension Attachment {
    enum Kind: Codable {
        case image(url: URL)
        case video(url: URL)
        case file(url: URL)
    }
}

struct Attachment: EntityModel, Codable {
    let id: String
    var kind: Kind

    @BelongsTo(\.message, inverse: \.attachment)
    var message: Message?

    mutating func normalize() {
        $message.normalize()
    }

    func save(to context: inout Context) throws {
        context.insert(self)
        try save(\.$message, inverse: \.$attachment, to: &context)
    }

    func delete(from context: inout Context) throws {
        context.remove(Attachment.self, id: id)
        detach(\.$message, inverse: \.$attachment, in: &context)
    }

}
