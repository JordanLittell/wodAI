// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class ReplanWeekMutation: GraphQLMutation {
  public static let operationName: String = "ReplanWeek"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "b7a9e301896e9b34c9ca64cee11574bf86eb47274735c67fe9d78fa3cc311110",
    definition: .init(
      #"mutation ReplanWeek($timezone: String!, $dates: [String!], $request: String, $replaceWorkoutIds: [String!]) { startWeeklyPlan( timezone: $timezone dates: $dates request: $request replaceWorkoutIds: $replaceWorkoutIds ) { __typename id status } }"#
    ))

  public var timezone: String
  public var dates: GraphQLNullable<[String]>
  public var request: GraphQLNullable<String>
  public var replaceWorkoutIds: GraphQLNullable<[String]>

  public init(
    timezone: String,
    dates: GraphQLNullable<[String]>,
    request: GraphQLNullable<String>,
    replaceWorkoutIds: GraphQLNullable<[String]>
  ) {
    self.timezone = timezone
    self.dates = dates
    self.request = request
    self.replaceWorkoutIds = replaceWorkoutIds
  }

  public var __variables: Variables? { [
    "timezone": timezone,
    "dates": dates,
    "request": request,
    "replaceWorkoutIds": replaceWorkoutIds
  ] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("startWeeklyPlan", StartWeeklyPlan.self, arguments: [
        "timezone": .variable("timezone"),
        "dates": .variable("dates"),
        "request": .variable("request"),
        "replaceWorkoutIds": .variable("replaceWorkoutIds")
      ]),
    ] }

    public var startWeeklyPlan: StartWeeklyPlan { __data["startWeeklyPlan"] }

    /// StartWeeklyPlan
    ///
    /// Parent Type: `WeeklyPlanJob`
    public struct StartWeeklyPlan: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.WeeklyPlanJob }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", WodAiAPI.ID.self),
        .field("status", GraphQLEnum<WodAiAPI.JobStatus>.self),
      ] }

      public var id: WodAiAPI.ID { __data["id"] }
      public var status: GraphQLEnum<WodAiAPI.JobStatus> { __data["status"] }
    }
  }
}
