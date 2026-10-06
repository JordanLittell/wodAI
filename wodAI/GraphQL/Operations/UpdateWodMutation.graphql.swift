// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class UpdateWodMutation: GraphQLMutation {
  public static let operationName: String = "UpdateWod"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "d728831eef6ce1455e8b0d57c3efefeadac1c18245dd1606635f28b89ac29a62",
    definition: .init(
      #"mutation UpdateWod($updateWodId: String!, $instructions: String!) { updateWod(id: $updateWodId, instructions: $instructions) { __typename id name description components { __typename order name definition description } } }"#
    ))

  public var updateWodId: String
  public var instructions: String

  public init(
    updateWodId: String,
    instructions: String
  ) {
    self.updateWodId = updateWodId
    self.instructions = instructions
  }

  public var __variables: Variables? { [
    "updateWodId": updateWodId,
    "instructions": instructions
  ] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("updateWod", UpdateWod.self, arguments: [
        "id": .variable("updateWodId"),
        "instructions": .variable("instructions")
      ]),
    ] }

    public var updateWod: UpdateWod { __data["updateWod"] }

    /// UpdateWod
    ///
    /// Parent Type: `Workout`
    public struct UpdateWod: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Workout }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", String.self),
        .field("name", String.self),
        .field("description", String.self),
        .field("components", [Component].self),
      ] }

      public var id: String { __data["id"] }
      public var name: String { __data["name"] }
      public var description: String { __data["description"] }
      public var components: [Component] { __data["components"] }

      /// UpdateWod.Component
      ///
      /// Parent Type: `Component`
      public struct Component: WodAiAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Component }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("order", Int.self),
          .field("name", String.self),
          .field("definition", String.self),
          .field("description", String.self),
        ] }

        public var order: Int { __data["order"] }
        public var name: String { __data["name"] }
        public var definition: String { __data["definition"] }
        public var description: String { __data["description"] }
      }
    }
  }
}
