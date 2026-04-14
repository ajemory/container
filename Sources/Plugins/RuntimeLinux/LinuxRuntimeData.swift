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
import ContainerizationOCI
import Foundation

/// Linux-specific runtime configuration data.
/// Encoded by the CLI, stored as the opaque runtimeData blob in RuntimeConfiguration,
/// decoded by the Linux runtime during provisioning.
public struct LinuxRuntimeData: Codable, Sendable {
    public let kernelPath: String
    public let kernelCommandLine: Kernel.CommandLine
    public let kernelPlatform: SystemPlatform
    public let initImageRef: String
    public let containerImageRef: String
    public let containerPlatform: Platform

    public init(
        kernelPath: String,
        kernelCommandLine: Kernel.CommandLine,
        kernelPlatform: SystemPlatform,
        initImageRef: String,
        containerImageRef: String,
        containerPlatform: Platform
    ) {
        self.kernelPath = kernelPath
        self.kernelCommandLine = kernelCommandLine
        self.kernelPlatform = kernelPlatform
        self.initImageRef = initImageRef
        self.containerImageRef = containerImageRef
        self.containerPlatform = containerPlatform
    }
}
