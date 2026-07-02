// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class HiitWorkoutLikeQuery: GraphQLQuery {
  public static let operationName: String = "HiitWorkoutLikeQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "ea31ae7523a0e2728463f10f20ffa0ff97042d366bddb2196496ba3e5bb4ae1f",
    definition: .init(
      #"query HiitWorkoutLikeQuery($workoutId: Int!) { hiitWorkoutLike(workoutId: $workoutId) }"#
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
      .field("hiitWorkoutLike", Int?.self, arguments: ["workoutId": .variable("workoutId")]),
    ] }

    public var hiitWorkoutLike: Int? { __data["hiitWorkoutLike"] }
  }
}
