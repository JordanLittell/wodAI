// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public struct InjuryInput: InputObject {
  public private(set) var __data: InputDict

  public init(_ data: InputDict) {
    __data = data
  }

  public init(
    bodyPart: String,
    severity: GraphQLEnum<WodAiAPI.InjurySeverity>,
    description: GraphQLNullable<String> = nil
  ) {
    __data = InputDict([
      "bodyPart": bodyPart,
      "severity": severity,
      "description": description
    ])
  }

  public var bodyPart: String {
    get { __data["bodyPart"] }
    set { __data["bodyPart"] = newValue }
  }

  public var severity: GraphQLEnum<WodAiAPI.InjurySeverity> {
    get { __data["severity"] }
    set { __data["severity"] = newValue }
  }

  public var description: GraphQLNullable<String> {
    get { __data["description"] }
    set { __data["description"] = newValue }
  }
}
