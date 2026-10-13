// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class HealthConnectionQuery: GraphQLQuery {
  public static let operationName: String = "HealthConnection"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "1f6fecfb705f31ece40dca3df91b02e5e75bdc072af8ab3f3e3da7f3733d9840",
    definition: .init(
      #"query HealthConnection { healthConnection { __typename syncedAt suggestedFitnessLevel } user { __typename fitnessLevel } }"#
    ))

  public init() {}

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("healthConnection", HealthConnection?.self),
      .field("user", User?.self),
    ] }

    public var healthConnection: HealthConnection? { __data["healthConnection"] }
    public var user: User? { __data["user"] }

    /// HealthConnection
    ///
    /// Parent Type: `HealthConnection`
    public struct HealthConnection: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.HealthConnection }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("syncedAt", WodAiAPI.DateTime.self),
        .field("suggestedFitnessLevel", GraphQLEnum<WodAiAPI.FitnessLevel>?.self),
      ] }

      public var syncedAt: WodAiAPI.DateTime { __data["syncedAt"] }
      public var suggestedFitnessLevel: GraphQLEnum<WodAiAPI.FitnessLevel>? { __data["suggestedFitnessLevel"] }
    }

    /// User
    ///
    /// Parent Type: `User`
    public struct User: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.User }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("fitnessLevel", GraphQLEnum<WodAiAPI.FitnessLevel>.self),
      ] }

      public var fitnessLevel: GraphQLEnum<WodAiAPI.FitnessLevel> { __data["fitnessLevel"] }
    }
  }
}
