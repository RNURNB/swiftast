/*
   Copyright 2016-2017 Ryuichi Intellectual Property and the Yanagiba project contributors

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

public class ExpressionPattern : PatternBase {
  public let expression: Expression

  public init(expression: Expression) {
    self.expression = expression
  }

  override public var sourceRange: SourceRange {
    return expression.sourceRange
  }

  // MARK: - ASTTextRepresentable

  override public var textDescription: String {
    return expression.textDescription
  }
}
