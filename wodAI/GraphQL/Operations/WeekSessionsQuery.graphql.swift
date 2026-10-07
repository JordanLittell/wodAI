// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class WeekSessionsQuery: GraphQLQuery {
  public static let operationName: String = "WeekSessions"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "acf0ea547e2341b48d3820b2645151c37885c5002b1e1e7a93f5d91f44b928a2",
    definition: .init(
      #"query WeekSessions($startDate: DateTime!, $endDate: DateTime!) { getWorkoutsByDateRange(startDate: $startDate, endDate: $endDate) { __typename ...SessionDetails } }"#,
      fragments: [SessionDetails.self]
    ))

  public var startDate: WodAiAPI.DateTime
  public var endDate: WodAiAPI.DateTime

  public init(
    startDate: WodAiAPI.DateTime,
    endDate: WodAiAPI.DateTime
  ) {
    self.startDate = startDate
    self.endDate = endDate
  }

  public var __variables: Variables? { [
    "startDate": startDate,
    "endDate": endDate
  ] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("getWorkoutsByDateRange", [GetWorkoutsByDateRange].self, arguments: [
        "startDate": .variable("startDate"),
        "endDate": .variable("endDate")
      ]),
    ] }

    public var getWorkoutsByDateRange: [GetWorkoutsByDateRange] { __data["getWorkoutsByDateRange"] }

    /// GetWorkoutsByDateRange
    ///
    /// Parent Type: `Workout`
    public struct GetWorkoutsByDateRange: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Workout }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .fragment(SessionDetails.self),
      ] }

      public var id: String { __data["id"] }
      public var name: String { __data["name"] }
      public var description: String { __data["description"] }
      public var stimulus: String? { __data["stimulus"] }
      public var coaching: String? { __data["coaching"] }
      public var scheduledDate: WodAiAPI.DateTime { __data["scheduledDate"] }
      public var source: GraphQLEnum<WodAiAPI.WorkoutSource> { __data["source"] }
      public var optional: Bool { __data["optional"] }
      public var blocks: [Block] { __data["blocks"] }

      public struct Fragments: FragmentContainer {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public var sessionDetails: SessionDetails { _toFragment() }
      }

      public typealias Block = SessionDetails.Block
    }
  }
}
