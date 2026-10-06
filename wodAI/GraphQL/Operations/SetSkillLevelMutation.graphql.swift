// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class SetSkillLevelMutation: GraphQLMutation {
  public static let operationName: String = "SetSkillLevel"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "a6db561e6516cadff352cb00e5b4c8fd070292b0227f23e7e319920a865e8f65",
    definition: .init(
      #"mutation SetSkillLevel($ladder: String!, $level: String) { setSkillLevel(ladder: $ladder, level: $level) { __typename key level } }"#
    ))

  public var ladder: String
  public var level: GraphQLNullable<String>

  public init(
    ladder: String,
    level: GraphQLNullable<String>
  ) {
    self.ladder = ladder
    self.level = level
  }

  public var __variables: Variables? { [
    "ladder": ladder,
    "level": level
  ] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("setSkillLevel", SetSkillLevel.self, arguments: [
        "ladder": .variable("ladder"),
        "level": .variable("level")
      ]),
    ] }

    public var setSkillLevel: SetSkillLevel { __data["setSkillLevel"] }

    /// SetSkillLevel
    ///
    /// Parent Type: `SkillLadder`
    public struct SetSkillLevel: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.SkillLadder }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("key", String.self),
        .field("level", String?.self),
      ] }

      public var key: String { __data["key"] }
      public var level: String? { __data["level"] }
    }
  }
}
