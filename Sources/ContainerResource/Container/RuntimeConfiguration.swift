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

/// Runtime-agnostic configuration for sandbox initialization.
/// Contains container metadata and an opaque runtime-specific data blob.
public struct RuntimeConfiguration: Sendable {
    static let runtimeConfigurationFilename = "runtime-configuration.json"

    /// Container root directory.
    public let path: URL

    /// Container configuration (common across all runtimes).
    public let containerConfiguration: ContainerConfiguration

    /// Container creation options (common across all runtimes).
    public let containerCreateOptions: ContainerCreateOptions

    /// Opaque runtime-specific data, encoded by the CLI and decoded by the runtime.
    public let runtimeData: Data?

    public init(
        path: URL,
        containerConfiguration: ContainerConfiguration,
        containerCreateOptions: ContainerCreateOptions,
        runtimeData: Data?
    ) {
        self.path = path
        self.containerConfiguration = containerConfiguration
        self.containerCreateOptions = containerCreateOptions
        self.runtimeData = runtimeData
    }

    public func writeRuntimeConfiguration() throws {
        let configPath = self.path.appendingPathComponent(Self.runtimeConfigurationFilename)
        let directory = configPath.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let encodedData = try JSONEncoder().encode(self)
        try encodedData.write(to: configPath)
    }

    public static func readRuntimeConfiguration(from runtimeConfigurationPath: URL) throws -> RuntimeConfiguration {
        let configurationPath = runtimeConfigurationPath.appendingPathComponent(RuntimeConfiguration.runtimeConfigurationFilename)
        guard FileManager.default.fileExists(atPath: configurationPath.path) else {
            throw ContainerizationError(
                .notFound,
                message: "runtime configuration file not found at path: \(configurationPath.path)"
            )
        }
        let data = try Data(contentsOf: configurationPath)
        return try JSONDecoder().decode(RuntimeConfiguration.self, from: data)
    }
}

// MARK: - Codable

extension RuntimeConfiguration: Codable {
    private enum CodingKeys: String, CodingKey {
        case path
        case containerConfiguration
        case containerCreateOptions
        case runtimeData
        // Legacy keys
        case kernel
        case initialFilesystem
        case containerRootFilesystem
        case options
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(path, forKey: .path)
        try container.encode(containerConfiguration, forKey: .containerConfiguration)
        try container.encode(containerCreateOptions, forKey: .containerCreateOptions)
        try container.encodeIfPresent(runtimeData, forKey: .runtimeData)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.path = try container.decode(URL.self, forKey: .path)

        // Legacy format: kernel/initialFilesystem at top level (pre-opaque-config)
        if container.contains(.kernel) {
            let kernel = try container.decode(Kernel.self, forKey: .kernel)

            struct LegacyLinuxRuntimeData: Codable {
                let kernelCommandLine: Kernel.CommandLine
                let kernelPlatform: SystemPlatform
            }
            let legacyData = LegacyLinuxRuntimeData(
                kernelCommandLine: kernel.commandLine,
                kernelPlatform: kernel.platform
            )
            self.runtimeData = try JSONEncoder().encode(legacyData)

            if let config = try container.decodeIfPresent(ContainerConfiguration.self, forKey: .containerConfiguration) {
                self.containerConfiguration = config
            } else {
                throw ContainerizationError(.invalidArgument, message: "legacy runtime configuration missing containerConfiguration")
            }
            if let opts = try container.decodeIfPresent(ContainerCreateOptions.self, forKey: .options) {
                self.containerCreateOptions = opts
            } else if let opts = try container.decodeIfPresent(ContainerCreateOptions.self, forKey: .containerCreateOptions) {
                self.containerCreateOptions = opts
            } else {
                self.containerCreateOptions = .default
            }
        }
        // New format
        else if container.contains(.containerConfiguration) {
            self.containerConfiguration = try container.decode(ContainerConfiguration.self, forKey: .containerConfiguration)
            self.runtimeData = try container.decodeIfPresent(Data.self, forKey: .runtimeData)

            if let opts = try container.decodeIfPresent(ContainerCreateOptions.self, forKey: .containerCreateOptions) {
                self.containerCreateOptions = opts
            } else if let opts = try container.decodeIfPresent(ContainerCreateOptions.self, forKey: .options) {
                self.containerCreateOptions = opts
            } else {
                self.containerCreateOptions = .default
            }
        } else {
            self.containerConfiguration = try container.decode(ContainerConfiguration.self, forKey: .containerConfiguration)
            self.containerCreateOptions = .default
            self.runtimeData = nil
        }
    }
}
