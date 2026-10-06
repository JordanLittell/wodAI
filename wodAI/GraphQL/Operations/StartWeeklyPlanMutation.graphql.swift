// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class StartWeeklyPlanMutation: GraphQLMutation {
  public static let operationName: String = "StartWeeklyPlan"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "8fce7b0e230cc02e3bbdc74ee8a2aa418a99be063e89bfb0ae9d4a36072d1ae8",
    definition: .init(
      #"mutation StartWeeklyPlan($timezone: String!) { startWeeklyPlan(timezone: $timezone) { __typename id status plannedDates message } }"#
    ))

  public var timezone: String

  public init(timezone: String) {
    self.timezone = timezone
  }

  public var __variables: Variables? { ["timezone": timezone] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("startWeeklyPlan", StartWeeklyPlan.self, arguments: ["timezone": .variable("timezone")]),
    ] }

    public var startWeeklyPlan: StartWeeklyPlan { __data["startWeeklyPlan"] }

    /// StartWeeklyPlan
    ///
    /// Parent Type: `PlanningRun`
    public struct StartWeeklyPlan: WodAiAPI.SelectionSet {
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
