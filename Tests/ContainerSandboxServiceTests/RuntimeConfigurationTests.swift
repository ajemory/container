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

import ContainerResource
import ContainerSandboxServiceClient
import Containerization
import ContainerizationOCI
import Foundation
import Testing

@Suite("RuntimeConfiguration Tests")
struct RuntimeConfigurationTests {

    @Test("Read non-existent runtime configuration throws error")
    func testReadNonExistentRuntimeConfiguration() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let nonExistentPath = tempDir.appendingPathComponent("non-existent-\(UUID()).json")

        #expect(throws: Error.self) {
            _ = try RuntimeConfiguration.readRuntimeConfiguration(from: nonExistentPath)
        }
    }

    @Test("RuntimeConfiguration round-trips with containerConfiguration and runtimeData")
    func testNewFormatRoundTrip() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let bundlePath = tempDir.appendingPathComponent("test-bundle-\(UUID())")

        defer {
            try? FileManager.default.removeItem(at: bundlePath)
        }

        let descriptor = Descriptor(
            mediaType: "application/vnd.oci.image.index.v1+json",
            digest: "sha256:1234567890abcdef",
            size: 1024
        )
        let containerConfig = ContainerConfiguration(
            id: "test-container",
            image: ImageDescription(reference: "test-image", descriptor: descriptor),
            process: ProcessConfiguration(
                executable: "/bin/sh",
                arguments: ["-c", "echo hello"],
                environment: ["PATH=/usr/bin:/bin"]
            )
        )

        let runtimeData = Data("test-runtime-data".utf8)

        let config = RuntimeConfiguration(
            path: bundlePath,
            containerConfiguration: containerConfig,
            containerCreateOptions: .default,
            runtimeData: runtimeData
        )

        try config.writeRuntimeConfiguration()
        let decoded = try RuntimeConfiguration.readRuntimeConfiguration(from: bundlePath)

        #expect(decoded.path == bundlePath)
        #expect(decoded.containerConfiguration.id == "test-container")
        #expect(decoded.containerCreateOptions.autoRemove == false)
        #expect(decoded.runtimeData == runtimeData)
    }

    @Test("RuntimeConfiguration with nil runtimeData")
    func testNilRuntimeData() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let bundlePath = tempDir.appendingPathComponent("test-bundle-\(UUID())")

        defer {
            try? FileManager.default.removeItem(at: bundlePath)
        }

        let descriptor = Descriptor(
            mediaType: "application/vnd.oci.image.index.v1+json",
            digest: "sha256:1234567890abcdef",
            size: 1024
        )
        let containerConfig = ContainerConfiguration(
            id: "test-nil-data",
            image: ImageDescription(reference: "test-image", descriptor: descriptor),
            process: ProcessConfiguration(
                executable: "/bin/sh",
                arguments: [],
                environment: []
            )
        )

        let config = RuntimeConfiguration(
            path: bundlePath,
            containerConfiguration: containerConfig,
            containerCreateOptions: .default,
            runtimeData: nil
        )

        try config.writeRuntimeConfiguration()
        let decoded = try RuntimeConfiguration.readRuntimeConfiguration(from: bundlePath)

        #expect(decoded.runtimeData == nil)
        #expect(decoded.containerConfiguration.id == "test-nil-data")
    }

    @Test("RuntimeConfiguration decodes legacy format")
    func testLegacyFormatDecode() throws {
        let descriptor = Descriptor(
            mediaType: "application/vnd.oci.image.index.v1+json",
            digest: "sha256:abc123",
            size: 1024
        )
        let containerConfig = ContainerConfiguration(
            id: "legacy-container",
            image: ImageDescription(reference: "ubuntu:latest", descriptor: descriptor),
            process: ProcessConfiguration(
                executable: "/bin/sh",
                arguments: [],
                environment: []
            )
        )

        let kernel = Kernel(
            path: URL(fileURLWithPath: "/path/to/kernel"),
            platform: .linuxArm
        )
        let initFs = Filesystem.virtiofs(
            source: "/path/to/initfs",
            destination: "/",
            options: ["ro"]
        )

        // Encode each piece and assemble into legacy format
        let encoder = JSONEncoder()
        let configJSON = try JSONSerialization.jsonObject(with: encoder.encode(containerConfig))
        let kernelJSON = try JSONSerialization.jsonObject(with: encoder.encode(kernel))
        let initFsJSON = try JSONSerialization.jsonObject(with: encoder.encode(initFs))

        let legacyJSON: [String: Any] = [
            "path": "/tmp/legacy-container",
            "containerConfiguration": configJSON,
            "initialFilesystem": initFsJSON,
            "kernel": kernelJSON,
        ]
        let data = try JSONSerialization.data(withJSONObject: legacyJSON)
        let decoded = try JSONDecoder().decode(RuntimeConfiguration.self, from: data)

        #expect(decoded.containerConfiguration.id == "legacy-container")
        #expect(decoded.runtimeData != nil)
    }
}
