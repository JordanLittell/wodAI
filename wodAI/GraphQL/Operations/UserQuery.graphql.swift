// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class UserQuery: GraphQLQuery {
  public static let operationName: String = "User"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "6413d55ec92295c2938b269ff8eac6023df99776c3195266736e080d326ab383",
    definition: .init(
      #"query User { user { __typename age fitnessLevel gender goal height weight activeDaysPerWeek sessionLengthMinutes } }"#
    ))

  public init() {}

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("user", User?.self),
    ] }

    public var user: User? { __data["user"] }

    /// User
    ///
    /// Parent Type: `User`
    public struct User: WodAiAPI.SelectionSet {
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
