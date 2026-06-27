// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class AbandonHIITSessionMutation: GraphQLMutation {
  public static let operationName: String = "AbandonHIITSession"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "d54f97391c2947f1475143ca685768fde0d6794c5cc0060f5b9b7d157af6ad41",
    definition: .init(
      #"mutation AbandonHIITSession($sessionId: ID!) { abandonHIITSession(sessionId: $sessionId) }"#
    ))

  public var sessionId: WodAiAPI.ID

  public init(sessionId: WodAiAPI.ID) {
    self.sessionId = sessionId
  }

  public var __variables: Variables? { ["sessionId": sessionId] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("abandonHIITSession", Bool.self, arguments: ["sessionId": .variable("sessionId")]),
    ] }

    public var abandonHIITSession: Bool { __data["abandonHIITSession"] }
  }
}
