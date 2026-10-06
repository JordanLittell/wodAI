// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class IsUserProvisionedQuery: GraphQLQuery {
  public static let operationName: String = "IsUserProvisioned"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "3d17780353158acb72c82734c427e39ef5f4375519325d6d059ecbe4cd9a6a99",
    definition: .init(
      #"query IsUserProvisioned { isUserProvisioned }"#
    ))

  public init() {}

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("isUserProvisioned", Bool.self),
    ] }

    public var isUserProvisioned: Bool { __data["isUserProvisioned"] }
  }
}
