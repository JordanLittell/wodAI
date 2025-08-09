// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class GenerateWorkoutScheduleMutation: GraphQLMutation {
  public static let operationName: String = "GenerateWorkoutSchedule"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "4713e91361869f04953aad4a5366ff1b570123d57a215579daf72581d1099c2f",
    definition: .init(
      #"mutation GenerateWorkoutSchedule { generateWorkoutSchedule { __typename success message scheduledDates } }"#
    ))

  public init() {}

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("generateWorkoutSchedule", GenerateWorkoutSchedule.self),
    ] }

    public var generateWorkoutSchedule: GenerateWorkoutSchedule { __data["generateWorkoutSchedule"] }

    /// GenerateWorkoutSchedule
    ///
    /// Parent Type: `WorkoutScheduleResponse`
    public struct GenerateWorkoutSchedule: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.WorkoutScheduleResponse }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("success", Bool.self),
        .field("message", String.self),
        .field("scheduledDates", [WodAiAPI.DateTime].self),
      ] }

      public var success: Bool { __data["success"] }
      public var message: String { __data["message"] }
      public var scheduledDates: [WodAiAPI.DateTime] { __data["scheduledDates"] }
    }
  }
}
