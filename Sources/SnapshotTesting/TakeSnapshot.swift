import XCTest

/// Takes a snapshot of the provided value and saves it on disk.
///
/// - Parameters:
///   - value: A value to take a snapshot of.
///   - snapshotting: A strategy for serializing, deserializing, and comparing values.
///   - name: An optional description of the snapshot.
///   - snapshotDirectory: Optional directory to save snapshots. By default snapshots will be saved in a directory with the same name as the test file, and that directory will sit inside a directory `__Snapshots__` that sits next to your test file.
///   - timeout: The amount of time a snapshot must be generated in.
///   - file: The file in which failure occurred. Defaults to the file name of the test case in which this function was called.
///   - testName: The name of the test in which failure occurred. Defaults to the function name of the test case in which this function was called with the 'test' prefix removed from the beginning.
///   - line: The line number on which failure occurred. Defaults to the line number on which this function was called.
/// - Returns: A failure message or nil.
public func takeSnapshot<Value, Format>(
  of value: @autoclosure () throws -> Value,
  as snapshotting: Snapshotting<Value, Format>,
  named name: String? = nil,
  snapshotDirectory: String? = nil,
  timeout: TimeInterval = 5,
  file: StaticString = #file,
  testName: String = #function,
  line: UInt = #line
  ) {

    do {
      let fileUrl = URL(fileURLWithPath: "\(file)", isDirectory: false)
      let fileName = fileUrl.deletingPathExtension().lastPathComponent

      let snapshotDirectoryUrl = snapshotDirectory.map { URL(fileURLWithPath: $0, isDirectory: true) }
        ?? fileUrl
          .deletingLastPathComponent()
          .appendingPathComponent("__Snapshots__")
          .appendingPathComponent(fileName)

      let snapshotName: String
      if let name {
        snapshotName = sanitizePathComponent(name)
      } else {
        snapshotName = testName.hasPrefix("test") ? sanitizePathComponent(String(testName.dropFirst("test".count))) : sanitizePathComponent(testName)
      }
      let snapshotFileUrl = snapshotDirectoryUrl
        .appendingPathComponent(snapshotName)
        .appendingPathExtension(snapshotting.pathExtension ?? "")
      let fileManager = FileManager.default
      try fileManager.createDirectory(at: snapshotDirectoryUrl, withIntermediateDirectories: true)

      let tookSnapshot = XCTestExpectation(description: "Took snapshot")
      var optionalDiffable: Format?
      snapshotting.snapshot(try value()).run { b in
        optionalDiffable = b
        tookSnapshot.fulfill()
      }
      let result = XCTWaiter.wait(for: [tookSnapshot], timeout: timeout)
      switch result {
      case .completed:
        break
      case .timedOut:
        XCTFail(
          """
          Exceeded timeout of \(timeout) seconds waiting for snapshot.

          This can happen when an asynchronously rendered view (like a web view) has not loaded. \
          Ensure that every subview of the view hierarchy has loaded to avoid timeouts, or, if a \
          timeout is unavoidable, consider setting the "timeout" parameter of "assertSnapshot" to \
          a higher value.
          """,
          file: file,
          line: line
        )
        return
      case .incorrectOrder, .invertedFulfillment, .interrupted:
        XCTFail("Couldn't snapshot value", file: file, line: line)
        return
      @unknown default:
        XCTFail("Couldn't snapshot value", file: file, line: line)
        return
      }

      guard let diffable = optionalDiffable else {
        XCTFail("Couldn't snapshot value", file: file, line: line)
        return
      }

      try snapshotting.diffing.toData(diffable).write(to: snapshotFileUrl)
    } catch {
      XCTFail(error.localizedDescription, file: file, line: line)
    }
}
