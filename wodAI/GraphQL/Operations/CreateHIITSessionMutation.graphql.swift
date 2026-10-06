// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class CreateHIITSessionMutation: GraphQLMutation {
  public static let operationName: String = "CreateHIITSession"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "a6b3890ebda4e46136a7c9d21db9245f14046405164e0a959d682d6507e58a1b",
    definition: .init(
      #"mutation CreateHIITSession($wodId: ID!, $startedAt: DateTime!, $source: SensorSourceInput) { createHIITSession(wodId: $wodId, startedAt: $startedAt, source: $source) { __typename id maxHeartRateUsed zoneThresholds } }"#
    ))

  public var wodId: WodAiAPI.ID
  public var startedAt: WodAiAPI.DateTime
  public var source: GraphQLNullable<WodAiAPI.SensorSourceInput>

  public init(
    wodId: WodAiAPI.ID,
    startedAt: WodAiAPI.DateTime,
    source: GraphQLNullable<WodAiAPI.SensorSourceInput>
  ) {
    self.wodId = wodId
    self.startedAt = startedAt
    self.source = source
  }

  public var __variables: Variables? { [
    "wodId": wodId,
    "startedAt": startedAt,
    "source": source
  ] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("createHIITSession", CreateHIITSession.self, arguments: [
        "wodId": .variable("wodId"),
        "startedAt": .variable("startedAt"),
        "source": .variable("source")
      ]),
    ] }

    public var createHIITSession: CreateHIITSession { __data["createHIITSession"] }

    /// CreateHIITSession
    ///
    /// Parent Type: `HIITSession`
    public struct CreateHIITSession: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.HIITSession }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", WodAiAPI.ID.self),
        .field("maxHeartRateUsed", Int.self),
        .field("zoneThresholds", [Int].self),
      ] }

      public var id: WodAiAPI.ID { __data["id"] }
      public var maxHeartRateUsed: Int { __data["maxHeartRateUsed"] }
      public var zoneThresholds: [Int] { __data["zoneThresholds"] }
    }
  }
}
