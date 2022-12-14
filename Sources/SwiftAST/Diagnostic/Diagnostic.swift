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

//import Source

public struct Diagnostic {
  public enum Level : String {
    case fatal
    case error
    case warning
  }

  public let level: Level
  public let kind: DiagnosticKind
  public let location: SourceLocation
  public let file: String
  public let function: String
  public let line: Int

  public init(level: Level, kind: DiagnosticKind, location: SourceLocation, file: String, function: String, line: Int) {
    self.level = level
    self.kind = kind
    self.location = location
    self.file=file
    self.function=function
    self.line=line
  }
  
  
  
  
  
  
  
  
  
}
