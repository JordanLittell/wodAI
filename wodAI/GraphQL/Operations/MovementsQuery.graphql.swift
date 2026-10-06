// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class MovementsQuery: GraphQLQuery {
  public static let operationName: String = "MovementsQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "f6760b5f3bacb1ee6667a5f6385b908f26fcaa929261b89c9e9bcb442d032b02",
    definition: .init(
      #"query MovementsQuery($search: String) { movements(search: $search) { __typename id name description patterns muscleGroups skillScore excluded } }"#
    ))

  public var search: GraphQLNullable<String>

  public init(search: GraphQLNullable<String>) {
    self.search = search
  }

  public var __variables: Variables? { ["search": search] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("movements", [Movement].self, arguments: ["search": .variable("search")]),
    ] }

    public var movements: [Movement] { __data["movements"] }

    /// Movement
    ///
    /// Parent Type: `HIITExercise`
    public struct Movement: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.HIITExercise }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", Int.self),
        .field("name", String.self),
        .field("description", String.self),
        .field("patterns", String.self),
        .field("muscleGroups", String.self),
        .field("skillScore", Int?.self),
        .field("excluded", Bool.self),
      ] }

      public var id: Int { __data["id"] }
      public var name: String { __data["name"] }
      public var description: String { __data["description"] }
      public var patterns: String { __data["patterns"] }
      public var muscleGroups: String { __data["muscleGroups"] }
      public var skillScore: Int? { __data["skillScore"] }
      public var excluded: Bool { __data["excluded"] }
    }
  }
}
