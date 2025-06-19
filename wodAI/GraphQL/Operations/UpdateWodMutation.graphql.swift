// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class UpdateWodMutation: GraphQLMutation {
  public static let operationName: String = "UpdateWod"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "756e4bc86c374c6a2c5ce54983d98218fa501ea9191c243b2f2ff823b61e1807",
    definition: .init(
      #"mutation UpdateWod($updateWodId: String!, $input: UpdateWodInput!) { updateWod(id: $updateWodId, input: $input) { __typename definition format id } }"#
    ))

  public var updateWodId: String
  public var input: WodAiAPI.UpdateWodInput

  public init(
    updateWodId: String,
    input: WodAiAPI.UpdateWodInput
  ) {
    self.updateWodId = updateWodId
    self.input = input
  }

  public var __variables: Variables? { [
    "updateWodId": updateWodId,
    "input": input
  ] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("updateWod", UpdateWod.self, arguments: [
        "id": .variable("updateWodId"),
        "input": .variable("input")
      ]),
    ] }

    public var updateWod: UpdateWod { __data["updateWod"] }

    /// UpdateWod
    ///
    /// Parent Type: `Wod`
    public struct UpdateWod: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Wod }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("definition", String.self),
        .field("format", String.self),
        .field("id", String.self),
      ] }

      public var definition: String { __data["definition"] }
      public var format: String { __data["format"] }
      public var id: String { __data["id"] }
    }
  }
}
