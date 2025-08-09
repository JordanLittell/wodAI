// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class GetWorkoutByDateQuery: GraphQLQuery {
  public static let operationName: String = "GetWorkoutByDate"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "6c2ae4dc6b355abd61e2079ce191751854fc0c474d4db3aaf0082a4acbf6a64f",
    definition: .init(
      #"query GetWorkoutByDate($date: DateTime!) { getWorkoutByDate(date: $date) { __typename id name description coaching stimulus scheduledDate status completed completedAt components { __typename id name definition description muscles movements order } } }"#
    ))

  public var date: WodAiAPI.DateTime

  public init(date: WodAiAPI.DateTime) {
    self.date = date
  }

  public var __variables: Variables? { ["date": date] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("getWorkoutByDate", GetWorkoutByDate?.self, arguments: ["date": .variable("date")]),
    ] }

    public var getWorkoutByDate: GetWorkoutByDate? { __data["getWorkoutByDate"] }

    /// GetWorkoutByDate
    ///
    /// Parent Type: `Workout`
    public struct GetWorkoutByDate: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Workout }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", String.self),
        .field("name", String.self),
        .field("description", String.self),
        .field("coaching", String?.self),
        .field("stimulus", String?.self),
        .field("scheduledDate", WodAiAPI.DateTime?.self),
        .field("status", GraphQLEnum<WodAiAPI.WorkoutStatus>.self),
        .field("completed", Bool.self),
        .field("completedAt", WodAiAPI.DateTime?.self),
        .field("components", [Component].self),
      ] }

      public var id: String { __data["id"] }
      public var name: String { __data["name"] }
      public var description: String { __data["description"] }
      public var coaching: String? { __data["coaching"] }
      public var stimulus: String? { __data["stimulus"] }
      public var scheduledDate: WodAiAPI.DateTime? { __data["scheduledDate"] }
      public var status: GraphQLEnum<WodAiAPI.WorkoutStatus> { __data["status"] }
      public var completed: Bool { __data["completed"] }
      public var completedAt: WodAiAPI.DateTime? { __data["completedAt"] }
      public var components: [Component] { __data["components"] }

      /// GetWorkoutByDate.Component
      ///
      /// Parent Type: `Component`
      public struct Component: WodAiAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Component }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("name", String.self),
          .field("definition", String.self),
          .field("description", String.self),
          .field("muscles", [String].self),
          .field("movements", [String].self),
          .field("order", Int.self),
        ] }

        public var id: String { __data["id"] }
        public var name: String { __data["name"] }
        public var definition: String { __data["definition"] }
        public var description: String { __data["description"] }
        public var muscles: [String] { __data["muscles"] }
        public var movements: [String] { __data["movements"] }
        public var order: Int { __data["order"] }
      }
    }
  }
}
