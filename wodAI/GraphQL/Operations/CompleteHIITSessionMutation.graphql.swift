// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class CompleteHIITSessionMutation: GraphQLMutation {
  public static let operationName: String = "CompleteHIITSession"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "ad314c41fb3b86fe72fa3d148be76ae0a12c0b00435189f902ff698bb13403f8",
    definition: .init(
      #"mutation CompleteHIITSession($sessionId: ID!, $endedAt: DateTime!) { completeHIITSession( sessionId: $sessionId endedAt: $endedAt movementIntervals: [] ) { __typename id heartRate { __typename ...HeartRateSummaryFields } } }"#,
      fragments: [HeartRateSummaryFields.self]
    ))

  public var sessionId: WodAiAPI.ID
  public var endedAt: WodAiAPI.DateTime

  public init(
    sessionId: WodAiAPI.ID,
    endedAt: WodAiAPI.DateTime
  ) {
    self.sessionId = sessionId
    self.endedAt = endedAt
  }

  public var __variables: Variables? { [
    "sessionId": sessionId,
    "endedAt": endedAt
  ] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("completeHIITSession", CompleteHIITSession.self, arguments: [
        "sessionId": .variable("sessionId"),
        "endedAt": .variable("endedAt"),
        "movementIntervals": []
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
        .field("heartRate", HeartRate?.self),
      ] }

      public var id: WodAiAPI.ID { __data["id"] }
      public var heartRate: HeartRate? { __data["heartRate"] }

      /// CompleteHIITSession.HeartRate
      ///
      /// Parent Type: `HeartRateSummary`
      public struct HeartRate: WodAiAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.HeartRateSummary }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .fragment(HeartRateSummaryFields.self),
        ] }

        public var avg: Double { __data["avg"] }
        public var max: Double { __data["max"] }
        public var min: Double { __data["min"] }
        public var coverage: Double { __data["coverage"] }
        public var zoneSeconds: [Int] { __data["zoneSeconds"] }
        public var trainingLoad: Double { __data["trainingLoad"] }
        public var estimatedCalories: Double? { __data["estimatedCalories"] }

        public struct Fragments: FragmentContainer {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public var heartRateSummaryFields: HeartRateSummaryFields { _toFragment() }
        }
      }
    }
  }
}
