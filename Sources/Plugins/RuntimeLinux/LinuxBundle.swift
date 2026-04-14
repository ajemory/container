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
import Containerization
import ContainerizationEXT4
import ContainerizationError
import Foundation
import SystemPackage

public final class LinuxBundle: ContainerResource.Bundle, @unchecked Sendable {
    static let initfsFilename = "initfs.ext4"
    static let kernelFilename = "kernel.json"
    static let kernelBinaryFilename = "kernel.bin"
    static let containerRootFsBlockFilename = "rootfs.ext4"
    static let containerRootFsFilename = "rootfs.json"

    public var containerRootfsBlock: URL {
        self.path.appendingPathComponent(Self.containerRootFsBlockFilename)
    }

    public var containerRootfs: Filesystem {
        get throws {
            try load(filename: Self.containerRootFsFilename)
        }
    }

    public var initialFilesystem: Filesystem {
        .block(
            format: "ext4",
            source: self.path.appendingPathComponent(Self.initfsFilename).path,
            destination: "/",
            options: ["ro"]
        )
    }

    public var kernel: Kernel {
        get throws {
            try load(filename: Self.kernelFilename)
        }
    }

    public func exportImage(to archive: URL) throws {
        let rootfs = self.containerRootfsBlock
        guard FileManager.default.fileExists(atPath: rootfs.path) else {
            throw ContainerizationError(.notFound, message: "no container image found to export")
        }
        try EXT4.EXT4Reader(blockDevice: FilePath(rootfs)).export(archive: FilePath(archive))
    }

    public func setContainerRootFs(fs: Filesystem) throws {
        try write(filename: Self.containerRootFsFilename, value: fs)
    }

    public func cloneContainerRootFs(cloning fs: Filesystem, readonly: Bool = false) throws {
        var mutableFs = fs
        if readonly && !mutableFs.options.contains("ro") {
            mutableFs.options.append("ro")
        }
        let cloned = try mutableFs.clone(to: self.containerRootfsBlock.absolutePath())
        try setContainerRootFs(fs: cloned)
    }
}
