// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class CompleteHiitWorkoutMutation: GraphQLMutation {
  public static let operationName: String = "CompleteHiitWorkoutMutation"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "0f888c706efe11970668e16fbadd3fb4dd13daa8a6af8566da4a622d3348e906",
    definition: .init(
      #"mutation CompleteHiitWorkoutMutation($id: Int!, $durationSeconds: Int, $roundsCompleted: Int, $repsCompleted: Int, $perceivedEffort: Int, $notes: String, $sessionId: ID, $pieceId: Int) { completeHiitWorkout( id: $id durationSeconds: $durationSeconds roundsCompleted: $roundsCompleted repsCompleted: $repsCompleted perceivedEffort: $perceivedEffort notes: $notes sessionId: $sessionId pieceId: $pieceId ) { __typename id completedAt durationSeconds roundsCompleted repsCompleted perceivedEffort notes } }"#
    ))

  public var id: Int
  public var durationSeconds: GraphQLNullable<Int>
  public var roundsCompleted: GraphQLNullable<Int>
  public var repsCompleted: GraphQLNullable<Int>
  public var perceivedEffort: GraphQLNullable<Int>
  public var notes: GraphQLNullable<String>
  public var sessionId: GraphQLNullable<WodAiAPI.ID>
  public var pieceId: GraphQLNullable<Int>

  public init(
    id: Int,
    durationSeconds: GraphQLNullable<Int>,
    roundsCompleted: GraphQLNullable<Int>,
    repsCompleted: GraphQLNullable<Int>,
    perceivedEffort: GraphQLNullable<Int>,
    notes: GraphQLNullable<String>,
    sessionId: GraphQLNullable<WodAiAPI.ID>,
    pieceId: GraphQLNullable<Int>
  ) {
    self.id = id
    self.durationSeconds = durationSeconds
    self.roundsCompleted = roundsCompleted
    self.repsCompleted = repsCompleted
    self.perceivedEffort = perceivedEffort
    self.notes = notes
    self.sessionId = sessionId
    self.pieceId = pieceId
  }

  public var __variables: Variables? { [
    "id": id,
    "durationSeconds": durationSeconds,
    "roundsCompleted": roundsCompleted,
    "repsCompleted": repsCompleted,
    "perceivedEffort": perceivedEffort,
    "notes": notes,
    "sessionId": sessionId,
    "pieceId": pieceId
  ] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("completeHiitWorkout", CompleteHiitWorkout.self, arguments: [
        "id": .variable("id"),
        "durationSeconds": .variable("durationSeconds"),
        "roundsCompleted": .variable("roundsCompleted"),
        "repsCompleted": .variable("repsCompleted"),
        "perceivedEffort": .variable("perceivedEffort"),
        "notes": .variable("notes"),
        "sessionId": .variable("sessionId"),
        "pieceId": .variable("pieceId")
      ]),
    ] }

    public var completeHiitWorkout: CompleteHiitWorkout { __data["completeHiitWorkout"] }

    /// CompleteHiitWorkout
    ///
    /// Parent Type: `CompletedHIITWorkout`
    public struct CompleteHiitWorkout: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.CompletedHIITWorkout }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", Int.self),
        .field("completedAt", WodAiAPI.DateTime.self),
        .field("durationSeconds", Int?.self),
        .field("roundsCompleted", Int?.self),
        .field("repsCompleted", Int?.self),
        .field("perceivedEffort", Int?.self),
        .field("notes", String?.self),
      ] }

      public var id: Int { __data["id"] }
      public var completedAt: WodAiAPI.DateTime { __data["completedAt"] }
      public var durationSeconds: Int? { __data["durationSeconds"] }
      public var roundsCompleted: Int? { __data["roundsCompleted"] }
      public var repsCompleted: Int? { __data["repsCompleted"] }
      public var perceivedEffort: Int? { __data["perceivedEffort"] }
      public var notes: String? { __data["notes"] }
    }
  }
}
