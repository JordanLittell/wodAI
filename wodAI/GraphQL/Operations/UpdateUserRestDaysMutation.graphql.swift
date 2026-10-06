// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class UpdateUserRestDaysMutation: GraphQLMutation {
  public static let operationName: String = "UpdateUserRestDays"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "8506737ccc09e59f1ba0ce550f88aa5c0d0c21c814146c70c54ad3602c3a0da9",
    definition: .init(
      #"mutation UpdateUserRestDays($restDays: [RestDay!]!) { updateUserRestDays(restDays: $restDays) { __typename id restDays } }"#
    ))

  public var restDays: [GraphQLEnum<WodAiAPI.RestDay>]

  public init(restDays: [GraphQLEnum<WodAiAPI.RestDay>]) {
    self.restDays = restDays
  }

  public var __variables: Variables? { ["restDays": restDays] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("updateUserRestDays", UpdateUserRestDays.self, arguments: ["restDays": .variable("restDays")]),
    ] }

    public var updateUserRestDays: UpdateUserRestDays { __data["updateUserRestDays"] }

    /// UpdateUserRestDays
    ///
    /// Parent Type: `User`
    public struct UpdateUserRestDays: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.User }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", Int.self),
        .field("restDays", [GraphQLEnum<WodAiAPI.RestDay>].self),
      ] }

      public var id: Int { __data["id"] }
      public var restDays: [GraphQLEnum<WodAiAPI.RestDay>] { __data["restDays"] }
    }
  }
}
