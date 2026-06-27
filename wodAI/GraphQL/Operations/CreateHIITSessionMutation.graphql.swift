// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class CreateHIITSessionMutation: GraphQLMutation {
  public static let operationName: String = "CreateHIITSession"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "85d5fac57a79309e2fdc1bca9ef7df185987c796156600155f87adc8bec705e9",
    definition: .init(
      #"mutation CreateHIITSession($wodId: ID!, $startedAt: DateTime!) { createHIITSession(wodId: $wodId, startedAt: $startedAt) { __typename id status startedAt } }"#
    ))

  public var wodId: WodAiAPI.ID
  public var startedAt: WodAiAPI.DateTime

  public init(
    wodId: WodAiAPI.ID,
    startedAt: WodAiAPI.DateTime
  ) {
    self.wodId = wodId
    self.startedAt = startedAt
  }

  public var __variables: Variables? { [
    "wodId": wodId,
    "startedAt": startedAt
  ] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("createHIITSession", CreateHIITSession.self, arguments: [
        "wodId": .variable("wodId"),
        "startedAt": .variable("startedAt")
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
        .field("status", GraphQLEnum<WodAiAPI.HIITSessionStatus>.self),
        .field("startedAt", WodAiAPI.DateTime.self),
      ] }

      public var id: WodAiAPI.ID { __data["id"] }
      public var status: GraphQLEnum<WodAiAPI.HIITSessionStatus> { __data["status"] }
      public var startedAt: WodAiAPI.DateTime { __data["startedAt"] }
    }
  }
}
