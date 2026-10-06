// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class OnboardingSkillLaddersQuery: GraphQLQuery {
  public static let operationName: String = "OnboardingSkillLadders"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "86ddfa9df83f9b61064d7fddff8b986e613103acf9a18c546bdd0972cd006ab9",
    definition: .init(
      #"query OnboardingSkillLadders { skillAssessment { __typename key name ladders { __typename key name rungs { __typename key question } } } }"#
    ))

  public init() {}

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("skillAssessment", [SkillAssessment].self),
    ] }

    public var skillAssessment: [SkillAssessment] { __data["skillAssessment"] }

    /// SkillAssessment
    ///
    /// Parent Type: `SkillDomain`
    public struct SkillAssessment: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.SkillDomain }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("key", String.self),
        .field("name", String.self),
        .field("ladders", [Ladder].self),
      ] }

      public var key: String { __data["key"] }
      public var name: String { __data["name"] }
      public var ladders: [Ladder] { __data["ladders"] }

      /// SkillAssessment.Ladder
      ///
      /// Parent Type: `SkillLadder`
      public struct Ladder: WodAiAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.SkillLadder }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("key", String.self),
          .field("name", String.self),
          .field("rungs", [Rung].self),
        ] }

        public var key: String { __data["key"] }
        public var name: String { __data["name"] }
        public var rungs: [Rung] { __data["rungs"] }

        /// SkillAssessment.Ladder.Rung
        ///
        /// Parent Type: `SkillRung`
        public struct Rung: WodAiAPI.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.SkillRung }
          public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("key", String.self),
            .field("question", String.self),
          ] }

          public var key: String { __data["key"] }
          public var question: String { __data["question"] }
        }
      }
    }
  }
}
