//
//  Extensions.swift
//  Subprocess
//
//  Created by Vaida on 2026-05-06.
//

#if os(macOS)
import Foundation
import System


extension FileHandle {
    
    public func write(_ string: some StringProtocol, terminator: String = "\n") throws {
        guard let data = string.data(using: .utf8), let terminator = terminator.data(using: .utf8) else { return }
        try self.write(contentsOf: data + terminator)
    }
    
}

#endif
