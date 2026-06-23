// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class CompleteHiitWorkoutMutation: GraphQLMutation {
  public static let operationName: String = "CompleteHiitWorkoutMutation"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "02b2f09692decddf01d8e264632f47cdb83d4d54120601fdebdf922fa2d9b42d",
    definition: .init(
      #"mutation CompleteHiitWorkoutMutation($id: Int!) { completeHiitWorkout(id: $id) }"#
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
      .field("completeHiitWorkout", Bool.self, arguments: ["id": .variable("id")]),
    ] }

    public var completeHiitWorkout: Bool { __data["completeHiitWorkout"] }
  }
}
