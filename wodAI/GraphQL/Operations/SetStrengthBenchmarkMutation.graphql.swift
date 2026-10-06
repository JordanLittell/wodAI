// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class SetStrengthBenchmarkMutation: GraphQLMutation {
  public static let operationName: String = "SetStrengthBenchmark"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "20bdff11c9f56befcd2f40ad2c1b4944a348382ac2f475b8ce39fd6b8f119494",
    definition: .init(
      #"mutation SetStrengthBenchmark($exerciseId: Int!, $weight: Float!, $reps: Int!) { setStrengthBenchmark(exerciseId: $exerciseId, weight: $weight, reps: $reps) { __typename id weight reps } }"#
    ))

  public var exerciseId: Int
  public var weight: Double
  public var reps: Int

  public init(
    exerciseId: Int,
    weight: Double,
    reps: Int
  ) {
    self.exerciseId = exerciseId
    self.weight = weight
    self.reps = reps
  }

  public var __variables: Variables? { [
    "exerciseId": exerciseId,
    "weight": weight,
    "reps": reps
  ] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("setStrengthBenchmark", SetStrengthBenchmark.self, arguments: [
        "exerciseId": .variable("exerciseId"),
        "weight": .variable("weight"),
        "reps": .variable("reps")
      ]),
    ] }

    public var setStrengthBenchmark: SetStrengthBenchmark { __data["setStrengthBenchmark"] }

    /// SetStrengthBenchmark
    ///
    /// Parent Type: `StrengthBenchmark`
    public struct SetStrengthBenchmark: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.StrengthBenchmark }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", Int.self),
        .field("weight", Double.self),
        .field("reps", Int.self),
      ] }

      public var id: Int { __data["id"] }
      public var weight: Double { __data["weight"] }
      public var reps: Int { __data["reps"] }
    }
  }
}
