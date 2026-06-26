// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class HIITWorkoutsQuery: GraphQLQuery {
  public static let operationName: String = "HIITWorkoutsQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "4bd79077cc5abdee40c9f751cd81a2af25ebf48e89c554b7f53afdf3ff4e1792",
    definition: .init(
      #"query HIITWorkoutsQuery($page: Int, $limit: Int) { hiitWorkouts(page: $page, limit: $limit) { __typename data { __typename id format displayText stimulus constraintType constraintMagnitude tags { __typename id name } } total page limit totalPages } }"#
    ))

  public var page: GraphQLNullable<Int>
  public var limit: GraphQLNullable<Int>

  public init(
    page: GraphQLNullable<Int>,
    limit: GraphQLNullable<Int>
  ) {
    self.page = page
    self.limit = limit
  }

  public var __variables: Variables? { [
    "page": page,
    "limit": limit
  ] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("hiitWorkouts", HiitWorkouts.self, arguments: [
        "page": .variable("page"),
        "limit": .variable("limit")
      ]),
    ] }

    public var hiitWorkouts: HiitWorkouts { __data["hiitWorkouts"] }

    /// HiitWorkouts
    ///
    /// Parent Type: `HIITPaginatedResponse`
    public struct HiitWorkouts: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.HIITPaginatedResponse }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("data", [Datum].self),
        .field("total", Int.self),
        .field("page", Int.self),
        .field("limit", Int.self),
        .field("totalPages", Int.self),
      ] }

      public var data: [Datum] { __data["data"] }
      public var total: Int { __data["total"] }
      public var page: Int { __data["page"] }
      public var limit: Int { __data["limit"] }
      public var totalPages: Int { __data["totalPages"] }

      /// HiitWorkouts.Datum
      ///
      /// Parent Type: `HIITWorkout`
      public struct Datum: WodAiAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.HIITWorkout }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", Int.self),
          .field("format", String?.self),
          .field("displayText", String.self),
          .field("stimulus", String.self),
          .field("constraintType", String.self),
          .field("constraintMagnitude", Int.self),
          .field("tags", [Tag]?.self),
        ] }

        public var id: Int { __data["id"] }
        public var format: String? { __data["format"] }
        public var displayText: String { __data["displayText"] }
        public var stimulus: String { __data["stimulus"] }
        public var constraintType: String { __data["constraintType"] }
        public var constraintMagnitude: Int { __data["constraintMagnitude"] }
        public var tags: [Tag]? { __data["tags"] }

        /// HiitWorkouts.Datum.Tag
        ///
        /// Parent Type: `Tag`
        public struct Tag: WodAiAPI.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Tag }
          public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", Int.self),
            .field("name", String.self),
          ] }

          public var id: Int { __data["id"] }
          public var name: String { __data["name"] }
        }
      }
    }
  }
}
