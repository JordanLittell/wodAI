// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class DisconnectAppleHealthMutation: GraphQLMutation {
  public static let operationName: String = "DisconnectAppleHealth"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "548feff79770d567258475ccf99d82f5637e8fbb04f8d1cc49542359a00bd2fe",
    definition: .init(
      #"mutation DisconnectAppleHealth { disconnectAppleHealth }"#
    ))

  public init() {}

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("disconnectAppleHealth", Bool.self),
    ] }

    public var disconnectAppleHealth: Bool { __data["disconnectAppleHealth"] }
  }
}
