// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class RecoveryStatusQuery: GraphQLQuery {
  public static let operationName: String = "RecoveryStatus"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "4dbaf467da77de9cae240c3fc7d2ef2753001a342eb50c2842c45532209dd409",
    definition: .init(
      #"query RecoveryStatus($timezone: String) { recoveryStatus(timezone: $timezone) { __typename status acuteLoad chronicLoad ratio lastHardSessionAt } }"#
    ))

  public var timezone: GraphQLNullable<String>

  public init(timezone: GraphQLNullable<String>) {
    self.timezone = timezone
  }

  public var __variables: Variables? { ["timezone": timezone] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("recoveryStatus", RecoveryStatus.self, arguments: ["timezone": .variable("timezone")]),
    ] }

    public var recoveryStatus: RecoveryStatus { __data["recoveryStatus"] }

    /// RecoveryStatus
    ///
    /// Parent Type: `RecoveryStatus`
    public struct RecoveryStatus: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.RecoveryStatus }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("status", GraphQLEnum<WodAiAPI.RecoveryLevel>.self),
        .field("acuteLoad", Double.self),
        .field("chronicLoad", Double.self),
        .field("ratio", Double?.self),
        .field("lastHardSessionAt", WodAiAPI.DateTime?.self),
      ] }

      public var status: GraphQLEnum<WodAiAPI.RecoveryLevel> { __data["status"] }
      public var acuteLoad: Double { __data["acuteLoad"] }
      public var chronicLoad: Double { __data["chronicLoad"] }
      public var ratio: Double? { __data["ratio"] }
      public var lastHardSessionAt: WodAiAPI.DateTime? { __data["lastHardSessionAt"] }
    }
  }
}
