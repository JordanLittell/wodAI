// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class UnsaveHiitWorkoutMutation: GraphQLMutation {
  public static let operationName: String = "UnsaveHiitWorkoutMutation"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "e693cc59a39b821f4e2dc298b021161a84337f653bd3b1eb8a67cf764a415d70",
    definition: .init(
      #"mutation UnsaveHiitWorkoutMutation($id: Int!) { unsaveHiitWorkout(id: $id) }"#
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
      .field("unsaveHiitWorkout", Bool.self, arguments: ["id": .variable("id")]),
    ] }

    public var unsaveHiitWorkout: Bool { __data["unsaveHiitWorkout"] }
  }
}
