// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class UpdateUserMutation: GraphQLMutation {
  public static let operationName: String = "UpdateUser"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "a102eaf6991d1d7bbe4a10125d2ef26b7e1d91a03016e66e2afaf63cecd6559f",
    definition: .init(
      #"mutation UpdateUser($input: UpdateUserInput!) { updateUser(input: $input) { __typename age fitnessLevel gender goal height weight activeDaysPerWeek sessionLengthMinutes } }"#
    ))

  public var input: WodAiAPI.UpdateUserInput

  public init(input: WodAiAPI.UpdateUserInput) {
    self.input = input
  }

  public var __variables: Variables? { ["input": input] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("updateUser", UpdateUser.self, arguments: ["input": .variable("input")]),
    ] }

    public var updateUser: UpdateUser { __data["updateUser"] }

    /// UpdateUser
    ///
    /// Parent Type: `User`
    public struct UpdateUser: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.User }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("age", Int?.self),
        .field("fitnessLevel", GraphQLEnum<WodAiAPI.FitnessLevel>.self),
        .field("gender", GraphQLEnum<WodAiAPI.Gender>?.self),
        .field("goal", String?.self),
        .field("height", Int?.self),
        .field("weight", Int?.self),
        .field("activeDaysPerWeek", Int?.self),
        .field("sessionLengthMinutes", Int?.self),
      ] }

      public var age: Int? { __data["age"] }
      public var fitnessLevel: GraphQLEnum<WodAiAPI.FitnessLevel> { __data["fitnessLevel"] }
      public var gender: GraphQLEnum<WodAiAPI.Gender>? { __data["gender"] }
      public var goal: String? { __data["goal"] }
      public var height: Int? { __data["height"] }
      public var weight: Int? { __data["weight"] }
      public var activeDaysPerWeek: Int? { __data["activeDaysPerWeek"] }
      public var sessionLengthMinutes: Int? { __data["sessionLengthMinutes"] }
    }
  }
}
