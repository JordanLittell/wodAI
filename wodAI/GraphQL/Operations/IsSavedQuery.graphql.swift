// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class IsSavedQuery: GraphQLQuery {
  public static let operationName: String = "IsSavedQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "e342ff5477eb2a432e8b3ba4e9d41655e5d41711867b9af32bd40f362e145ec6",
    definition: .init(
      #"query IsSavedQuery($workoutId: Int!) { isSaved(workoutId: $workoutId) }"#
    ))

  public var workoutId: Int

  public init(workoutId: Int) {
    self.workoutId = workoutId
  }

  public var __variables: Variables? { ["workoutId": workoutId] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("isSaved", Bool.self, arguments: ["workoutId": .variable("workoutId")]),
    ] }

    public var isSaved: Bool { __data["isSaved"] }
  }
}
