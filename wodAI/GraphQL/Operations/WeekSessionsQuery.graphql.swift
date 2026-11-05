// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class WeekSessionsQuery: GraphQLQuery {
  public static let operationName: String = "WeekSessions"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "b27e802a10a5e9ea9e79ce614e1be96c0bfff2c5649fb5f2f2515cb5e3f39dae",
    definition: .init(
      #"query WeekSessions($startDate: DateTime!, $endDate: DateTime!) { getWorkoutsByDateRange(startDate: $startDate, endDate: $endDate) { __typename ...SessionDetails } }"#,
      fragments: [HiitLineFields.self, SessionDetails.self]
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
      public var createdAt: WodAiAPI.DateTime { __data["createdAt"] }
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
