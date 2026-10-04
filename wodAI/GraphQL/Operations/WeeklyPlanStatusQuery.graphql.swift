// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class WeeklyPlanStatusQuery: GraphQLQuery {
  public static let operationName: String = "WeeklyPlanStatus"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "88b1611e035162fd13e6e052874e0b3d4090cf5523b0fc97d3674b59b9c8a5bd",
    definition: .init(
      #"query WeeklyPlanStatus { weeklyPlanStatus { __typename id status plannedDates message } }"#
    ))

  public init() {}

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("weeklyPlanStatus", WeeklyPlanStatus?.self),
    ] }

    public var weeklyPlanStatus: WeeklyPlanStatus? { __data["weeklyPlanStatus"] }

    /// WeeklyPlanStatus
    ///
    /// Parent Type: `PlanningRun`
    public struct WeeklyPlanStatus: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.PlanningRun }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", Int.self),
        .field("status", GraphQLEnum<WodAiAPI.PlanningRunStatus>.self),
        .field("plannedDates", [String].self),
        .field("message", String?.self),
      ] }

      public var id: Int { __data["id"] }
      public var status: GraphQLEnum<WodAiAPI.PlanningRunStatus> { __data["status"] }
      public var plannedDates: [String] { __data["plannedDates"] }
      public var message: String? { __data["message"] }
    }
  }
}
