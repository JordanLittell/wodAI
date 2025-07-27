// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class CurrentWODQuery: GraphQLQuery {
  public static let operationName: String = "CurrentWOD"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "778f100fa72dd31532e5be466c47dc160b9d5cdc33f676b7887912731829c835",
    definition: .init(
      #"query CurrentWOD { currentWod { __typename id name description completed components { __typename id name definition order } } }"#
    ))

  public init() {}

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("currentWod", CurrentWod?.self),
    ] }

    public var currentWod: CurrentWod? { __data["currentWod"] }

    /// CurrentWod
    ///
    /// Parent Type: `Workout`
    public struct CurrentWod: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Workout }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", String.self),
        .field("name", String.self),
        .field("description", String.self),
        .field("completed", Bool.self),
        .field("components", [Component].self),
      ] }

      public var id: String { __data["id"] }
      public var name: String { __data["name"] }
      public var description: String { __data["description"] }
      public var completed: Bool { __data["completed"] }
      public var components: [Component] { __data["components"] }

      /// CurrentWod.Component
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
          .field("order", Int.self),
        ] }

        public var id: String { __data["id"] }
        public var name: String { __data["name"] }
        public var definition: String { __data["definition"] }
        public var order: Int { __data["order"] }
      }
    }
  }
}
