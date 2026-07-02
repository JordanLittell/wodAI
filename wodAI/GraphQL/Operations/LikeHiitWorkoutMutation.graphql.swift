// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class LikeHiitWorkoutMutation: GraphQLMutation {
  public static let operationName: String = "LikeHiitWorkoutMutation"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "eec51bfb30607ebe148b224ee3d8251247ec27c306bde5ab8514fc0f3f387309",
    definition: .init(
      #"mutation LikeHiitWorkoutMutation($workoutId: Int!, $score: Int!) { likeHiitWorkout(workoutId: $workoutId, score: $score) }"#
    ))

  public var workoutId: Int
  public var score: Int

  public init(
    workoutId: Int,
    score: Int
  ) {
    self.workoutId = workoutId
    self.score = score
  }

  public var __variables: Variables? { [
    "workoutId": workoutId,
    "score": score
  ] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("likeHiitWorkout", Bool.self, arguments: [
        "workoutId": .variable("workoutId"),
        "score": .variable("score")
      ]),
    ] }

    public var likeHiitWorkout: Bool { __data["likeHiitWorkout"] }
  }
}
