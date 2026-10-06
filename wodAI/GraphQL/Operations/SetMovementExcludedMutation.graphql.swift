// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class SetMovementExcludedMutation: GraphQLMutation {
  public static let operationName: String = "SetMovementExcludedMutation"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "f0d1d3e54c00079111159e300083ef8590c7bc445c6023f4872b72883af7235a",
    definition: .init(
      #"mutation SetMovementExcludedMutation($exerciseId: Int!, $excluded: Boolean!) { setMovementExcluded(exerciseId: $exerciseId, excluded: $excluded) { __typename id excluded } }"#
    ))

  public var exerciseId: Int
  public var excluded: Bool

  public init(
    exerciseId: Int,
    excluded: Bool
  ) {
    self.exerciseId = exerciseId
    self.excluded = excluded
  }

  public var __variables: Variables? { [
    "exerciseId": exerciseId,
    "excluded": excluded
  ] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("setMovementExcluded", SetMovementExcluded.self, arguments: [
        "exerciseId": .variable("exerciseId"),
        "excluded": .variable("excluded")
      ]),
    ] }

    public var setMovementExcluded: SetMovementExcluded { __data["setMovementExcluded"] }

    /// SetMovementExcluded
    ///
    /// Parent Type: `HIITExercise`
    public struct SetMovementExcluded: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.HIITExercise }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", Int.self),
        .field("excluded", Bool.self),
      ] }

      public var id: Int { __data["id"] }
      public var excluded: Bool { __data["excluded"] }
    }
  }
}
