// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class SaveHiitWorkoutMutation: GraphQLMutation {
  public static let operationName: String = "SaveHiitWorkoutMutation"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "c13c6d8cd9bd2f4dcfddd4045ef8042d3397bffe2eb6312a951c949fe92f20c7",
    definition: .init(
      #"mutation SaveHiitWorkoutMutation($id: Int!) { saveHiitWorkout(id: $id) }"#
    ))

  public var id: Int

  public init(id: Int) {
    self.id = id
  }

  public var __variables: Variables? { ["id": id] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("saveHiitWorkout", Bool.self, arguments: ["id": .variable("id")]),
    ] }

    public var saveHiitWorkout: Bool { __data["saveHiitWorkout"] }
  }
}
