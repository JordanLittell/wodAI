// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class CompleteOnboardingMutation: GraphQLMutation {
  public static let operationName: String = "CompleteOnboarding"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "ce0c1156fe6e323cafd8ee850f0e87e266806b218c7cc030aa32c91b1a2a2f8f",
    definition: .init(
      #"mutation CompleteOnboarding($timezone: String!) { completeOnboarding(timezone: $timezone) { __typename id } }"#
    ))

  public var timezone: String

  public init(timezone: String) {
    self.timezone = timezone
  }

  public var __variables: Variables? { ["timezone": timezone] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("completeOnboarding", CompleteOnboarding.self, arguments: ["timezone": .variable("timezone")]),
    ] }

    public var completeOnboarding: CompleteOnboarding { __data["completeOnboarding"] }

    /// CompleteOnboarding
    ///
    /// Parent Type: `User`
    public struct CompleteOnboarding: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.User }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", Int.self),
      ] }

      public var id: Int { __data["id"] }
    }
  }
}
