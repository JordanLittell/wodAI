// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class GenerateWODMutation: GraphQLMutation {
  public static let operationName: String = "GenerateWODMutation"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "731016d0b1388d924c1691e81b843f65d74deb963590bf566bf8550d0f01da59",
    definition: .init(
      #"mutation GenerateWODMutation($input: CreateWodInput!) { generateWod(input: $input) { __typename format definition id } }"#
    ))

  public var input: WodAiAPI.CreateWodInput

  public init(input: WodAiAPI.CreateWodInput) {
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
        .field("format", String.self),
        .field("definition", String.self),
        .field("id", String.self),
      ] }

      public var format: String { __data["format"] }
      public var definition: String { __data["definition"] }
      public var id: String { __data["id"] }
    }
  }
}
