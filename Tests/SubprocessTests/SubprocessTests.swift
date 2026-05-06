import Testing
import Foundation
@testable import Subprocess

@Suite
struct SubprocessTests {
    
    @Test func directReturn() async throws {
        let (stdout, stderr) = try await Subprocess.run(
            "/bin/ls",
            workingDirectory: "/Users/vaida/Library/Mobile Documents/com~apple~CloudDocs/DataBase/Projects/Packages/Subprocess/Tests"
        )

        #expect(stdout == "SubprocessTests\n")
        #expect(stderr == nil)
    }
    
    @Test func inputOutput() async throws {
        let subprocess = try Subprocess.makeSubprocess("/opt/homebrew/bin/calc")
        
        var lines = subprocess.stdout.bytes.lines.makeAsyncIterator()
        try subprocess.stdin.write("1 + 1")
        let next = try await lines.next()?.trimmingCharacters(in: .whitespaces)
        #expect(next == "2")
    }
}
