// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GenerateWODMutation: GraphQLMutation {
  public static let operationName: String = "GenerateWODMutation"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"mutation GenerateWODMutation($input: CreateWodInput!) { generateWod(input: $input) { __typename name definition id } }"#
    ))

  public var input: CreateWodInput

  public init(input: CreateWodInput) {
    self.input = input
  }

  public var __variables: Variables? { ["input": input] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("generateWod", GenerateWod.self, arguments: ["input": .variable("input")]),
    ] }

    public var generateWod: GenerateWod { __data["generateWod"] }

    /// GenerateWod
    ///
    /// Parent Type: `Wod`
    public struct GenerateWod: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Wod }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("name", String.self),
        .field("definition", String.self),
        .field("id", String.self),
      ] }

      public var name: String { __data["name"] }
      public var definition: String { __data["definition"] }
      public var id: String { __data["id"] }
    }
  }
}
