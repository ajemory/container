//===----------------------------------------------------------------------===//
// Copyright © 2026 Apple Inc. and the container project authors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//===----------------------------------------------------------------------===//

import Containerization
import ContainerizationError
import Foundation

open class Bundle: @unchecked Sendable {
    public static let containerConfigFilename = "config.json"
    public static let containerOptionsFilename = "options.json"
    private static let containerLogFilename = "stdio.log"
    private static let bootLogFilename = "boot.log"

    public let path: URL

    public required init(path: URL) {
        self.path = path
    }

    open var configuration: ContainerConfiguration {
        get throws {
            try load(path: self.path.appendingPathComponent(Self.containerConfigFilename))
        }
    }

    open var containerLog: URL {
        self.path.appendingPathComponent(Self.containerLogFilename)
    }

    open var bootlog: URL {
        self.path.appendingPathComponent(Self.bootLogFilename)
    }

    /// Create the bundle directory and write common metadata files.
    /// Runtime subclasses call this first, then write runtime-specific files.
    @discardableResult
    open class func create(
        path: URL,
        configuration: ContainerConfiguration,
        options: ContainerCreateOptions
    ) throws -> Self {
        try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
        let bundle = Self.init(path: path)
        try bundle.write(filename: Self.containerConfigFilename, value: configuration)
        try bundle.write(filename: Self.containerOptionsFilename, value: options)
        return bundle
    }

    public func set(configuration: ContainerConfiguration) throws {
        try write(filename: Self.containerConfigFilename, value: configuration)
    }

    public func filePath(for name: String) -> URL {
        path.appendingPathComponent(name)
    }

    open func delete() throws {
        try FileManager.default.removeItem(at: self.path)
    }

    public func write(filename: String, value: Encodable) throws {
        try Self.write(self.path.appendingPathComponent(filename), value: value)
    }

    public static func write(_ path: URL, value: Encodable) throws {
        let data = try JSONEncoder().encode(value)
        try data.write(to: path)
    }

    public func load<T>(filename: String) throws -> T where T: Decodable {
        try load(path: self.path.appendingPathComponent(filename))
    }

    public func load<T>(path: URL) throws -> T where T: Decodable {
        let data = try Data(contentsOf: path)
        return try JSONDecoder().decode(T.self, from: data)
    }
}
