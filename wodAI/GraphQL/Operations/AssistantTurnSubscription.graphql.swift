// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class AssistantTurnSubscription: GraphQLSubscription {
  public static let operationName: String = "AssistantTurn"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "69f5cf3a22d5b062205f67d2cba6ae0ec8f44c2880f1e003422cfd562dbbc1a9",
    definition: .init(
      #"subscription AssistantTurn($input: AssistantTurnInput!) { assistantTurn(input: $input) { __typename ... on AssistantTextDelta { text } ... on AssistantSuggestions { suggestions { __typename id label action payload } } ... on AssistantAction { kind request scheduledDate dates replaceWorkoutIds } ... on AssistantTurnComplete { text } ... on GenerationFailed { message } } }"#
    ))

  public var input: WodAiAPI.AssistantTurnInput

  public init(input: WodAiAPI.AssistantTurnInput) {
    self.input = input
  }

  public var __variables: Variables? { ["input": input] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Subscription }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("assistantTurn", AssistantTurn.self, arguments: ["input": .variable("input")]),
    ] }

    public var assistantTurn: AssistantTurn { __data["assistantTurn"] }

    /// AssistantTurn
    ///
    /// Parent Type: `AssistantTurnEvent`
    public struct AssistantTurn: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Unions.AssistantTurnEvent }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .inlineFragment(AsAssistantTextDelta.self),
        .inlineFragment(AsAssistantSuggestions.self),
        .inlineFragment(AsAssistantAction.self),
        .inlineFragment(AsAssistantTurnComplete.self),
        .inlineFragment(AsGenerationFailed.self),
      ] }

      public var asAssistantTextDelta: AsAssistantTextDelta? { _asInlineFragment() }
      public var asAssistantSuggestions: AsAssistantSuggestions? { _asInlineFragment() }
      public var asAssistantAction: AsAssistantAction? { _asInlineFragment() }
      public var asAssistantTurnComplete: AsAssistantTurnComplete? { _asInlineFragment() }
      public var asGenerationFailed: AsGenerationFailed? { _asInlineFragment() }

      /// AssistantTurn.AsAssistantTextDelta
      ///
      /// Parent Type: `AssistantTextDelta`
      public struct AsAssistantTextDelta: WodAiAPI.InlineFragment {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public typealias RootEntityType = AssistantTurnSubscription.Data.AssistantTurn
        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.AssistantTextDelta }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("text", String.self),
        ] }

        public var text: String { __data["text"] }
      }

      /// AssistantTurn.AsAssistantSuggestions
      ///
      /// Parent Type: `AssistantSuggestions`
      public struct AsAssistantSuggestions: WodAiAPI.InlineFragment {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public typealias RootEntityType = AssistantTurnSubscription.Data.AssistantTurn
        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.AssistantSuggestions }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("suggestions", [Suggestion].self),
        ] }

        public var suggestions: [Suggestion] { __data["suggestions"] }

        /// AssistantTurn.AsAssistantSuggestions.Suggestion
        ///
        /// Parent Type: `AssistantSuggestion`
        public struct Suggestion: WodAiAPI.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.AssistantSuggestion }
          public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", String.self),
            .field("label", String.self),
            .field("action", GraphQLEnum<WodAiAPI.AssistantSuggestionAction>.self),
            .field("payload", String?.self),
          ] }

          public var id: String { __data["id"] }
          public var label: String { __data["label"] }
          public var action: GraphQLEnum<WodAiAPI.AssistantSuggestionAction> { __data["action"] }
          public var payload: String? { __data["payload"] }
        }
      }

      /// AssistantTurn.AsAssistantAction
      ///
      /// Parent Type: `AssistantAction`
      public struct AsAssistantAction: WodAiAPI.InlineFragment {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public typealias RootEntityType = AssistantTurnSubscription.Data.AssistantTurn
        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.AssistantAction }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("kind", GraphQLEnum<WodAiAPI.AssistantActionKind>.self),
          .field("request", String?.self),
          .field("scheduledDate", String?.self),
          .field("dates", [String]?.self),
          .field("replaceWorkoutIds", [String]?.self),
        ] }

        public var kind: GraphQLEnum<WodAiAPI.AssistantActionKind> { __data["kind"] }
        public var request: String? { __data["request"] }
        public var scheduledDate: String? { __data["scheduledDate"] }
        public var dates: [String]? { __data["dates"] }
        public var replaceWorkoutIds: [String]? { __data["replaceWorkoutIds"] }
      }

      /// AssistantTurn.AsAssistantTurnComplete
      ///
      /// Parent Type: `AssistantTurnComplete`
      public struct AsAssistantTurnComplete: WodAiAPI.InlineFragment {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public typealias RootEntityType = AssistantTurnSubscription.Data.AssistantTurn
        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.AssistantTurnComplete }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("text", String.self),
        ] }

        public var text: String { __data["text"] }
      }

      /// AssistantTurn.AsGenerationFailed
      ///
      /// Parent Type: `GenerationFailed`
      public struct AsGenerationFailed: WodAiAPI.InlineFragment {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public typealias RootEntityType = AssistantTurnSubscription.Data.AssistantTurn
        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.GenerationFailed }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("message", String.self),
        ] }

        public var message: String { __data["message"] }
      }
    }
  }
}
