// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class GenerateHiitWorkoutMutation: GraphQLMutation {
  public static let operationName: String = "GenerateHiitWorkoutMutation"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "e08a45769baa435757334097c759ea3e9b4b725a674e1fdcbbdc0e94e10180f7",
    definition: .init(
      #"mutation GenerateHiitWorkoutMutation($skipWorkoutId: Int, $tagIds: [Int!]) { generateHiitWorkout(skipWorkoutId: $skipWorkoutId, tagIds: $tagIds) { __typename id format displayText stimulus constraintType constraintMagnitude tags { __typename id name } } }"#
    ))

  public var skipWorkoutId: GraphQLNullable<Int>
  public var tagIds: GraphQLNullable<[Int]>

  public init(
    skipWorkoutId: GraphQLNullable<Int>,
    tagIds: GraphQLNullable<[Int]>
  ) {
    self.skipWorkoutId = skipWorkoutId
    self.tagIds = tagIds
  }

  public var __variables: Variables? { [
    "skipWorkoutId": skipWorkoutId,
    "tagIds": tagIds
  ] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("generateHiitWorkout", GenerateHiitWorkout?.self, arguments: [
        "skipWorkoutId": .variable("skipWorkoutId"),
        "tagIds": .variable("tagIds")
      ]),
    ] }

    public var generateHiitWorkout: GenerateHiitWorkout? { __data["generateHiitWorkout"] }

    /// GenerateHiitWorkout
    ///
    /// Parent Type: `HIITWorkout`
    public struct GenerateHiitWorkout: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.HIITWorkout }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", Int.self),
        .field("format", String?.self),
        .field("displayText", String.self),
        .field("stimulus", String.self),
        .field("constraintType", String.self),
        .field("constraintMagnitude", Int.self),
        .field("tags", [Tag]?.self),
      ] }

      public var id: Int { __data["id"] }
      public var format: String? { __data["format"] }
      public var displayText: String { __data["displayText"] }
      public var stimulus: String { __data["stimulus"] }
      public var constraintType: String { __data["constraintType"] }
      public var constraintMagnitude: Int { __data["constraintMagnitude"] }
      public var tags: [Tag]? { __data["tags"] }

      /// GenerateHiitWorkout.Tag
      ///
      /// Parent Type: `Tag`
      public struct Tag: WodAiAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Tag }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", Int.self),
          .field("name", String.self),
        ] }

        public var id: Int { __data["id"] }
        public var name: String { __data["name"] }
      }
    }
  }
}
