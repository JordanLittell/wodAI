// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class DeleteWorkoutMutation: GraphQLMutation {
  public static let operationName: String = "DeleteWorkout"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "31c32d0cc4936dfbafb5b43a988140a3e068fdeb946dbbb2630c72ea48e348cc",
    definition: .init(
      #"mutation DeleteWorkout($id: String!) { deleteWorkout(id: $id) }"#
    ))

  public var id: String

  public init(id: String) {
    self.id = id
  }

  public var __variables: Variables? { ["id": id] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("deleteWorkout", Bool.self, arguments: ["id": .variable("id")]),
    ] }

    public var deleteWorkout: Bool { __data["deleteWorkout"] }
  }
}
