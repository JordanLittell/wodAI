// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class CompleteHIITSessionMutation: GraphQLMutation {
  public static let operationName: String = "CompleteHIITSession"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "82a53e078837fff6d3a4da68f3e8f0e28f7bfab36e8b2a7553a731bea4bea9ad",
    definition: .init(
      #"mutation CompleteHIITSession($sessionId: ID!, $endedAt: DateTime!, $movementIntervals: [MovementIntervalInput!]!) { completeHIITSession( sessionId: $sessionId endedAt: $endedAt movementIntervals: $movementIntervals ) { __typename id status durationSeconds } }"#
    ))

  public var sessionId: WodAiAPI.ID
  public var endedAt: WodAiAPI.DateTime
  public var movementIntervals: [WodAiAPI.MovementIntervalInput]

  public init(
    sessionId: WodAiAPI.ID,
    endedAt: WodAiAPI.DateTime,
    movementIntervals: [WodAiAPI.MovementIntervalInput]
  ) {
    self.sessionId = sessionId
    self.endedAt = endedAt
    self.movementIntervals = movementIntervals
  }

  public var __variables: Variables? { [
    "sessionId": sessionId,
    "endedAt": endedAt,
    "movementIntervals": movementIntervals
  ] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("completeHIITSession", CompleteHIITSession.self, arguments: [
        "sessionId": .variable("sessionId"),
        "endedAt": .variable("endedAt"),
        "movementIntervals": .variable("movementIntervals")
      ]),
    ] }

    public var completeHIITSession: CompleteHIITSession { __data["completeHIITSession"] }

    /// CompleteHIITSession
    ///
    /// Parent Type: `HIITSession`
    public struct CompleteHIITSession: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.HIITSession }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", WodAiAPI.ID.self),
        .field("status", GraphQLEnum<WodAiAPI.HIITSessionStatus>.self),
        .field("durationSeconds", Double?.self),
      ] }

      public var id: WodAiAPI.ID { __data["id"] }
      public var status: GraphQLEnum<WodAiAPI.HIITSessionStatus> { __data["status"] }
      public var durationSeconds: Double? { __data["durationSeconds"] }
    }
  }
}
