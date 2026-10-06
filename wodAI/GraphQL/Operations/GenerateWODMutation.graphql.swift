// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class GenerateWODMutation: GraphQLMutation {
  public static let operationName: String = "GenerateWODMutation"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "30374af7564928be4e0f3e4d7c2de376e7329444ad84fc507ba94abe4c7883cd",
    definition: .init(
      #"mutation GenerateWODMutation { generateWod { __typename id name description components { __typename description order name definition } } }"#
    ))

  public init() {}

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("generateWod", GenerateWod.self),
    ] }

    public var generateWod: GenerateWod { __data["generateWod"] }

    /// GenerateWod
    ///
    /// Parent Type: `Workout`
    public struct GenerateWod: WodAiAPI.SelectionSet {
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

      /// GenerateWod.Component
      ///
      /// Parent Type: `Component`
      public struct Component: WodAiAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Component }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("description", String.self),
          .field("order", Int.self),
          .field("name", String.self),
          .field("definition", String.self),
        ] }

        public var description: String { __data["description"] }
        public var order: Int { __data["order"] }
        public var name: String { __data["name"] }
        public var definition: String { __data["definition"] }
      }
    }
  }
}
