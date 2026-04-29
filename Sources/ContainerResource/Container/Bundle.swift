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

/// Contract for runtime-specific bundle types.
/// Provides standardized file conventions and common operations.
/// Each runtime defines a conforming struct with additional runtime-specific properties.
public protocol Bundle: Sendable {
    var path: URL { get }
    init(path: URL)
}

// MARK: - Standardized filenames

extension Bundle {
    public static var containerConfigFilename: String { "config.json" }
    public static var containerOptionsFilename: String { "options.json" }
}

// MARK: - Default implementations

extension Bundle {
    public var configuration: ContainerConfiguration {
        get throws {
            try load(filename: Self.containerConfigFilename)
        }
    }

    public var containerLog: URL {
        path.appendingPathComponent("stdio.log")
    }

    public var bootlog: URL {
        path.appendingPathComponent("boot.log")
    }

    /// Create the bundle directory and write common metadata files.
    @discardableResult
    public static func create(
        path: URL,
        configuration: ContainerConfiguration,
        options: ContainerCreateOptions
    ) throws -> Self {
        try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
        let bundle = Self(path: path)
        try bundle.write(filename: containerConfigFilename, value: configuration)
        try bundle.write(filename: containerOptionsFilename, value: options)
        return bundle
    }

    public func set(configuration: ContainerConfiguration) throws {
        try write(filename: Self.containerConfigFilename, value: configuration)
    }

    public func filePath(for name: String) -> URL {
        path.appendingPathComponent(name)
    }

    public func delete() throws {
        try FileManager.default.removeItem(at: self.path)
    }

    public func write(filename: String, value: Encodable) throws {
        let data = try JSONEncoder().encode(value)
        try data.write(to: path.appendingPathComponent(filename))
    }

    public func load<T>(filename: String) throws -> T where T: Decodable {
        let data = try Data(contentsOf: path.appendingPathComponent(filename))
        return try JSONDecoder().decode(T.self, from: data)
    }
}

// MARK: - ContainerBundle

/// Default bundle type used by the API server for common operations.
public struct ContainerBundle: Bundle {
    public let path: URL

    public init(path: URL) {
        self.path = path
    }
}
