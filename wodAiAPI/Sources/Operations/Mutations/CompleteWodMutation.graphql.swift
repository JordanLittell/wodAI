// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class CompleteWodMutation: GraphQLMutation {
  public static let operationName: String = "CompleteWodMutation"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"mutation CompleteWodMutation($completeWodId: String!) { completeWod(id: $completeWodId) { __typename definition completed createdAt } }"#
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
    /// Parent Type: `Wod`
    public struct CompleteWod: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Wod }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("definition", String.self),
        .field("completed", Bool.self),
        .field("createdAt", WodAiAPI.DateTime?.self),
      ] }

      public var definition: String { __data["definition"] }
      public var completed: Bool { __data["completed"] }
      public var createdAt: WodAiAPI.DateTime? { __data["createdAt"] }
    }
  }
}
