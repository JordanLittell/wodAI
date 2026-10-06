// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class CompleteWodMutation: GraphQLMutation {
  public static let operationName: String = "CompleteWodMutation"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "af4f2972fabc41e0af3f1c9b642e5bc3aae7183522da09588a49c3ccf3509bad",
    definition: .init(
      #"mutation CompleteWodMutation($completeWodId: String!) { completeWod(id: $completeWodId) { __typename completed } }"#
    ))

  public var completeWodId: String

  public init(completeWodId: String) {
    self.completeWodId = completeWodId
  }

  public var __variables: Variables? { ["completeWodId": completeWodId] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("completeWod", CompleteWod.self, arguments: ["id": .variable("completeWodId")]),
    ] }

    public var completeWod: CompleteWod { __data["completeWod"] }

    /// CompleteWod
    ///
    /// Parent Type: `Workout`
    public struct CompleteWod: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Workout }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("completed", Bool.self),
      ] }

      public var completed: Bool { __data["completed"] }
    }
  }
}
