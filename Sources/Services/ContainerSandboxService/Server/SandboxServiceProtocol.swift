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
import ContainerXPC
import Containerization
import ContainerizationError
import Foundation
import Logging
import NIO

/// Protocol defining the interface for runtime-specific sandbox services.
/// Each runtime implements this protocol to handle sandbox lifecycle and 
/// container execution.
///
/// The SandboxClient interface remains consistent across all implementations,
/// so all methods take and return XPCMessage for client compatibility.
public protocol SandboxServiceProtocol: Actor {
    /// Create an endpoint for XPC communication.
    func createEndpoint(_ message: XPCMessage) async throws -> XPCMessage

    /// Bootstrap the container with the initial process.
    func bootstrap(_ message: XPCMessage) async throws -> XPCMessage

    /// Start a process in the container.
    func startProcess(_ message: XPCMessage) async throws -> XPCMessage

    /// Get container statistics.
    func statistics(_ message: XPCMessage) async throws -> XPCMessage

    /// Shutdown the sandbox.
    func shutdown(_ message: XPCMessage) async throws -> XPCMessage

    /// Create a new process in the container.
    func createProcess(_ message: XPCMessage) async throws -> XPCMessage

    /// Get the current state of the sandbox.
    func state(_ message: XPCMessage) async throws -> XPCMessage

    /// Stop the sandbox.
    func stop(_ message: XPCMessage) async throws -> XPCMessage

    /// Kill a process in the container.
    func kill(_ message: XPCMessage) async throws -> XPCMessage

    /// Resize the terminal.
    func resize(_ message: XPCMessage) async throws -> XPCMessage

    /// Wait for a process to exit.
    func wait(_ message: XPCMessage) async throws -> XPCMessage

    /// Establish a network connection.
    func dial(_ message: XPCMessage) async throws -> XPCMessage

    /// Export the container's filesystem image.
    func export(_ message: XPCMessage) async throws -> XPCMessage

    /// Provision the container bundle without starting the VM.
    func provision(_ message: XPCMessage) async throws -> XPCMessage
}
