/*
   Copyright 2015-2017 Ryuichi Intellectual Property and the Yanagiba project contributors

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

import Foundation
//import Source

public struct DiagnosticStopper : Error { // TODO: need a better way to stop the parser
}

public class DiagnosticPool {
  public static let shared = DiagnosticPool()

  public var _diagnostics: [Diagnostic] = []
  private var _checkpoints: [String: [Diagnostic]] = [:]
  public var hasErrors:Bool=false
  
  public var diagnostics:[Diagnostic] {_diagnostics}

  public func appendFatal(
    kind: DiagnosticKind, sourceLocatable: SourceLocatable
  ) -> Error {
    _append(.fatal, kind, sourceLocatable)
    return DiagnosticStopper()
  }

  public func appendError(
    kind: DiagnosticKind, sourceLocatable: SourceLocatable
  ) throws {
    _append(.error, kind, sourceLocatable)
    if _diagnostics.filter({ $0.level == .error }).count >= 10 {
      throw DiagnosticStopper()
    }
  }

  public func appendWarning(
    kind: DiagnosticKind, sourceLocatable: SourceLocatable
  ) throws {
    _append(.warning, kind, sourceLocatable)
    if _diagnostics.filter({ $0.level == .warning }).count >= 50 {
      throw DiagnosticStopper()
    }
  }

  private func _append(
    _ level: Diagnostic.Level,
    _ kind: DiagnosticKind,
    _ source: SourceLocatable
  ) {
    if level == .error || level == .fatal {hasErrors=true}
    let diagnostic = Diagnostic(
      level: level, kind: kind, location: source.sourceLocation)
    //print("DiagnosticPool._append:",diagnostic)
    _diagnostics.append(diagnostic)
  }

  public func report(withConsumer consumer: DiagnosticConsumer) {
    consumer.consume(diagnostics: _diagnostics)
    clear()
  }

  public func clear() {
    DiagnosticPool.shared._diagnostics = []
    hasErrors=false
  }

  public func checkPoint() -> String {
    let id = UUID().uuidString
    _checkpoints[id] = _diagnostics
    return id
  }

  @discardableResult public func restore(fromCheckpoint cpId: String) -> Bool {
    guard let loadedDiagnostics = _checkpoints[cpId] else {
      return false
    }
    DiagnosticPool.shared._diagnostics = loadedDiagnostics
    return true
  }
}
