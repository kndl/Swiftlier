//
//  FileArchiver.swift
//  Swiftlier
//
//  Created by Andrew J Wagner on 2/27/16.
//  Copyright © 2016 Drewag LLC. All rights reserved.
//

#if os(iOS)
import Foundation

public struct FileArchive: ErrorGenerating {
    public static func archiveEncodable(_ encodable: Encodable, toFile file: String, options: Data.WritingOptions = .atomicWrite, encrypt: (Data) throws -> Data = {return $0}) throws {
        let object = NativeTypesEncoder.objectFromEncodable(encodable, mode: .saveLocally)

        let data = try self.data(from: object, encrypt: encrypt)
        try data.write(to: URL(fileURLWithPath: file), options: Data.WritingOptions.atomicWrite.union(options))
    }

    public static func archiveDictionaryOfEncodable<E: Encodable>(_ dictionary: [String:E], toFile file: String, options: Data.WritingOptions = .atomicWrite, encrypt: (Data) throws -> Data = {return $0}) throws {
        var finalDict = [String:Any]()

        for (key, value) in dictionary {
            finalDict[key] = NativeTypesEncoder.objectFromEncodable(value, mode: .saveLocally)
        }

        let data = try self.data(from: finalDict, encrypt: encrypt)
        try data.write(to: URL(fileURLWithPath: file), options: Data.WritingOptions.atomicWrite.union(options))
    }

    public static func archiveArrayOfEncodable<E: Encodable>(_ array: [E], toFile file: String, options: Data.WritingOptions = .atomicWrite, encrypt: (Data) throws -> Data = {return $0}) throws {
        var finalArray = [Any]()

        for value in array {
            finalArray.append(NativeTypesEncoder.objectFromEncodable(value, mode: .saveLocally))
        }

        let data = try self.data(from: finalArray, encrypt: encrypt)
        try data.write(to: URL(fileURLWithPath: file), options: Data.WritingOptions.atomicWrite.union(options))
    }

    public static func unarchiveEncodableFromFile<E: Decodable>(_ file: String, decrypt: (Data) throws -> Data = {return $0}) throws -> E {
        guard var data = try? Data(contentsOf: URL(fileURLWithPath: file)) else {
            throw self.error("unarching \(E.self)", because: "the file does not exist")
        }
        data = try decrypt(data)

        guard let object = try self.object(from: data, decrypt: decrypt) else {
            throw self.error("unarching \(E.self)", because: "the file is invalid")
        }

        let value: E = try NativeTypesDecoder.decodableTypeFromObject(object, mode: .saveLocally)
        return value
    }

    public static func unarchiveDictionaryOfEncodableFromFile<E: Decodable>(_ file: String, decrypt: (Data) throws -> Data = {return $0}) throws -> [String:E]? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: file)) else {
            return nil
        }

        guard let rawDict = try self.object(from: data, decrypt: decrypt) as? [String:[String: Any]] else {
            throw self.error("unarching \(E.self)", because: "the file is invalid")
        }

        var finalDict = [String:E]()

        for (key, subDict) in rawDict {
            finalDict[key] = try NativeTypesDecoder.decodableTypeFromObject(subDict, mode: .saveLocally) as E
        }

        return finalDict
    }

    public static func unarchiveArrayOfEncodableFromFile<E: Decodable>(_ file: String, decrypt: (Data) throws -> Data = {return $0}) throws -> [E]? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: file)) else {
            return nil
        }

        guard let rawArray = try self.object(from: data, decrypt: decrypt) as? [Any] else {
            throw self.error("unarching \(E.self)", because: "the file is invalid")
        }

        var finalArray = [E]()

        for rawObject in rawArray {
            if let object: E = try? NativeTypesDecoder.decodableTypeFromObject(rawObject, mode: .saveLocally) {
                finalArray.append(object)
            }
        }

        return finalArray
    }
}

private extension FileArchive {
    static func data(from object: Any, encrypt: (Data) throws -> Data) throws -> Data {
        return try encrypt(NSKeyedArchiver.archivedData(withRootObject: object))
        //return try JSONSerialization.data(withJSONObject: object, options: .prettyPrinted)
    }

    static func object(from data: Data, decrypt: (Data) throws -> Data) throws -> Any? {
        let data = try decrypt(data)
        return NSKeyedUnarchiver.unarchiveObject(with: data)
        //return try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions())
    }
}
#endif
