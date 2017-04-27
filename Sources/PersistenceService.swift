//
//  PersistenceService.swift
//  Swiftlier
//
//  Created by Andrew J Wagner on 3/26/17.
//  Copyright © 2017 Drewag. All rights reserved.
//

import Foundation

open class PersistenceService<Value: Codable> {
    public var values: [Value]!
    let directory: DirectoryPath

    public init(to: DirectoryPath = FileSystem.default.documentsDirectory) throws {
        self.directory = to
        try self.reload()
    }

    public func reload() throws {
        self.values = try self.loadValues()
    }

    public func save() throws {
        try self.save(values: self.values)
    }
}

extension PersistenceService {
    var valueName: String {
        return "\(Value.self)"
    }

    func archivePath() throws -> Path {
        return try self.directory.file("\(self.valueName.lowercased())s.plist")
    }

    func loadValues() throws -> [Value] {
        guard let archive = try self.archivePath().file else {
            return []
        }
        return try archive.decodableArray()
    }

    func save(values: [Value]) throws {
        try self.archivePath().createFile(containingEncodable: values, canOverwrite: true)
    }
}
