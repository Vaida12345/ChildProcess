//
//  Extensions.swift
//  ChildProcess
//
//  Created by Vaida on 2026-05-06.
//

#if os(macOS)
import Foundation
import System


extension FileHandle {
    
    public func write(_ string: some StringProtocol, terminator: String = "\n") throws {
        try self.write(contentsOf: Data(string.utf8) + Data(terminator.utf8))
    }
    
}

#endif
