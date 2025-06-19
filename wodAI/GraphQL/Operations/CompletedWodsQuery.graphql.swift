// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class CompletedWodsQuery: GraphQLQuery {
  public static let operationName: String = "CompletedWodsQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "63aa7840ab5341f7ec8a8b8f05862dcee36106531c89f03a6d2c2014a64ee3ce",
    definition: .init(
      #"query CompletedWodsQuery($page: Int) { completedWods(page: $page) { __typename wods { __typename definition muscles name updatedAt } hasMore currentPage } }"#
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
        .field("hasMore", Bool.self),
        .field("currentPage", Int.self),
      ] }

      public var wods: [Wod] { __data["wods"] }
      public var hasMore: Bool { __data["hasMore"] }
      public var currentPage: Int { __data["currentPage"] }

      /// CompletedWods.Wod
      ///
      /// Parent Type: `Wod`
      public struct Wod: WodAiAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Wod }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("definition", String.self),
          .field("muscles", [String].self),
          .field("name", String.self),
          .field("updatedAt", WodAiAPI.DateTime?.self),
        ] }

        public var definition: String { __data["definition"] }
        public var muscles: [String] { __data["muscles"] }
        public var name: String { __data["name"] }
        public var updatedAt: WodAiAPI.DateTime? { __data["updatedAt"] }
      }
    }
  }
}
