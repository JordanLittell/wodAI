// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class CompletedWodsQuery: GraphQLQuery {
  public static let operationName: String = "CompletedWodsQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "f61f1d03076fb78e737705c4931f8df431de8272dda56db4f26ea02eb220412b",
    definition: .init(
      #"query CompletedWodsQuery($page: Int) { completedWods(page: $page) { __typename wods { __typename id name description completedAt stimulus components { __typename definition muscles name } createdAt updatedAt } total hasMore currentPage totalPages } }"#
    ))

  public var page: GraphQLNullable<Int>

  public init(page: GraphQLNullable<Int>) {
    self.page = page
  }

  public var __variables: Variables? { ["page": page] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("completedWods", CompletedWods.self, arguments: ["page": .variable("page")]),
    ] }

    public var completedWods: CompletedWods { __data["completedWods"] }

    /// CompletedWods
    ///
    /// Parent Type: `CompletedWodsResponse`
    public struct CompletedWods: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.CompletedWodsResponse }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("wods", [Wod].self),
        .field("total", Int.self),
        .field("hasMore", Bool.self),
        .field("currentPage", Int.self),
        .field("totalPages", Int.self),
      ] }

      public var wods: [Wod] { __data["wods"] }
      public var total: Int { __data["total"] }
      public var hasMore: Bool { __data["hasMore"] }
      public var currentPage: Int { __data["currentPage"] }
      public var totalPages: Int { __data["totalPages"] }

      /// CompletedWods.Wod
      ///
      /// Parent Type: `Workout`
      public struct Wod: WodAiAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Workout }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("name", String.self),
          .field("description", String.self),
          .field("completedAt", WodAiAPI.DateTime?.self),
          .field("stimulus", String?.self),
          .field("components", [Component].self),
          .field("createdAt", WodAiAPI.DateTime.self),
          .field("updatedAt", WodAiAPI.DateTime.self),
        ] }

        public var id: String { __data["id"] }
        public var name: String { __data["name"] }
        public var description: String { __data["description"] }
        public var completedAt: WodAiAPI.DateTime? { __data["completedAt"] }
        public var stimulus: String? { __data["stimulus"] }
        public var components: [Component] { __data["components"] }
        public var createdAt: WodAiAPI.DateTime { __data["createdAt"] }
        public var updatedAt: WodAiAPI.DateTime { __data["updatedAt"] }

        /// CompletedWods.Wod.Component
        ///
        /// Parent Type: `Component`
        public struct Component: WodAiAPI.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Component }
          public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("definition", String.self),
            .field("muscles", [String].self),
            .field("name", String.self),
          ] }

          public var definition: String { __data["definition"] }
          public var muscles: [String] { __data["muscles"] }
          public var name: String { __data["name"] }
        }
      }
    }
  }
}
