// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class UpdateHiitCompletionMutation: GraphQLMutation {
  public static let operationName: String = "UpdateHiitCompletion"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "15206ece2293bf7b430d2c558239f93d94bdd48eac95211b0be08724c6c1faa4",
    definition: .init(
      #"mutation UpdateHiitCompletion($id: Int!, $durationSeconds: Int, $roundsCompleted: Int, $repsCompleted: Int, $perceivedEffort: Int) { updateHiitCompletion( id: $id durationSeconds: $durationSeconds roundsCompleted: $roundsCompleted repsCompleted: $repsCompleted perceivedEffort: $perceivedEffort ) { __typename id durationSeconds roundsCompleted repsCompleted perceivedEffort trainingLoad } }"#
    ))

  public var id: Int
  public var durationSeconds: GraphQLNullable<Int>
  public var roundsCompleted: GraphQLNullable<Int>
  public var repsCompleted: GraphQLNullable<Int>
  public var perceivedEffort: GraphQLNullable<Int>

  public init(
    id: Int,
    durationSeconds: GraphQLNullable<Int>,
    roundsCompleted: GraphQLNullable<Int>,
    repsCompleted: GraphQLNullable<Int>,
    perceivedEffort: GraphQLNullable<Int>
  ) {
    self.id = id
    self.durationSeconds = durationSeconds
    self.roundsCompleted = roundsCompleted
    self.repsCompleted = repsCompleted
    self.perceivedEffort = perceivedEffort
  }

  public var __variables: Variables? { [
    "id": id,
    "durationSeconds": durationSeconds,
    "roundsCompleted": roundsCompleted,
    "repsCompleted": repsCompleted,
    "perceivedEffort": perceivedEffort
  ] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("updateHiitCompletion", UpdateHiitCompletion.self, arguments: [
        "id": .variable("id"),
        "durationSeconds": .variable("durationSeconds"),
        "roundsCompleted": .variable("roundsCompleted"),
        "repsCompleted": .variable("repsCompleted"),
        "perceivedEffort": .variable("perceivedEffort")
      ]),
    ] }

    public var updateHiitCompletion: UpdateHiitCompletion { __data["updateHiitCompletion"] }

    /// UpdateHiitCompletion
    ///
    /// Parent Type: `CompletedHIITWorkout`
    public struct UpdateHiitCompletion: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.CompletedHIITWorkout }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", Int.self),
        .field("durationSeconds", Int?.self),
        .field("roundsCompleted", Int?.self),
        .field("repsCompleted", Int?.self),
        .field("perceivedEffort", Int?.self),
        .field("trainingLoad", Double?.self),
      ] }

      public var id: Int { __data["id"] }
      public var durationSeconds: Int? { __data["durationSeconds"] }
      public var roundsCompleted: Int? { __data["roundsCompleted"] }
      public var repsCompleted: Int? { __data["repsCompleted"] }
      public var perceivedEffort: Int? { __data["perceivedEffort"] }
      public var trainingLoad: Double? { __data["trainingLoad"] }
    }
  }
}
