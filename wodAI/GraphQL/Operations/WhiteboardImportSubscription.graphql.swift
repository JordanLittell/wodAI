// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class WhiteboardImportSubscription: GraphQLSubscription {
  public static let operationName: String = "WhiteboardImport"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "8029bf83d8ef1e34f6480ceb9cb06e0d61a11c9899aad1f6be32c0161e20c830",
    definition: .init(
      #"subscription WhiteboardImport($input: WhiteboardImportInput!) { whiteboardImport(input: $input) { __typename ... on GenerationSession { name description stimulus } ... on GenerationStrengthBlock { order name instructions } ... on GenerationStrengthSet { order setOrder reps weight rpe exercise { __typename name muscleGroups videoUrl } } ... on GenerationDraftHiitBlock { order name format displayText stimulus } ... on GenerationComplete { workout { __typename ...SessionDetails } } ... on GenerationFailed { message } } }"#,
      fragments: [SessionDetails.self]
    ))

  public var input: WodAiAPI.WhiteboardImportInput

  public init(input: WodAiAPI.WhiteboardImportInput) {
    self.input = input
  }

  public var __variables: Variables? { ["input": input] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Subscription }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("whiteboardImport", WhiteboardImport.self, arguments: ["input": .variable("input")]),
    ] }

    public var whiteboardImport: WhiteboardImport { __data["whiteboardImport"] }

    /// WhiteboardImport
    ///
    /// Parent Type: `WorkoutGenerationEvent`
    public struct WhiteboardImport: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Unions.WorkoutGenerationEvent }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .inlineFragment(AsGenerationSession.self),
        .inlineFragment(AsGenerationStrengthBlock.self),
        .inlineFragment(AsGenerationStrengthSet.self),
        .inlineFragment(AsGenerationDraftHiitBlock.self),
        .inlineFragment(AsGenerationComplete.self),
        .inlineFragment(AsGenerationFailed.self),
      ] }

      public var asGenerationSession: AsGenerationSession? { _asInlineFragment() }
      public var asGenerationStrengthBlock: AsGenerationStrengthBlock? { _asInlineFragment() }
      public var asGenerationStrengthSet: AsGenerationStrengthSet? { _asInlineFragment() }
      public var asGenerationDraftHiitBlock: AsGenerationDraftHiitBlock? { _asInlineFragment() }
      public var asGenerationComplete: AsGenerationComplete? { _asInlineFragment() }
      public var asGenerationFailed: AsGenerationFailed? { _asInlineFragment() }

      /// WhiteboardImport.AsGenerationSession
      ///
      /// Parent Type: `GenerationSession`
      public struct AsGenerationSession: WodAiAPI.InlineFragment {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public typealias RootEntityType = WhiteboardImportSubscription.Data.WhiteboardImport
        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.GenerationSession }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("name", String.self),
          .field("description", String.self),
          .field("stimulus", String.self),
        ] }

        public var name: String { __data["name"] }
        public var description: String { __data["description"] }
        public var stimulus: String { __data["stimulus"] }
      }

      /// WhiteboardImport.AsGenerationStrengthBlock
      ///
      /// Parent Type: `GenerationStrengthBlock`
      public struct AsGenerationStrengthBlock: WodAiAPI.InlineFragment {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public typealias RootEntityType = WhiteboardImportSubscription.Data.WhiteboardImport
        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.GenerationStrengthBlock }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("order", Int.self),
          .field("name", String.self),
          .field("instructions", String.self),
        ] }

        public var order: Int { __data["order"] }
        public var name: String { __data["name"] }
        public var instructions: String { __data["instructions"] }
      }

      /// WhiteboardImport.AsGenerationStrengthSet
      ///
      /// Parent Type: `GenerationStrengthSet`
      public struct AsGenerationStrengthSet: WodAiAPI.InlineFragment {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public typealias RootEntityType = WhiteboardImportSubscription.Data.WhiteboardImport
        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.GenerationStrengthSet }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("order", Int.self),
          .field("setOrder", Int.self),
          .field("reps", Int.self),
          .field("weight", Double?.self),
          .field("rpe", Int?.self),
          .field("exercise", Exercise.self),
        ] }

        public var order: Int { __data["order"] }
        public var setOrder: Int { __data["setOrder"] }
        public var reps: Int { __data["reps"] }
        public var weight: Double? { __data["weight"] }
        public var rpe: Int? { __data["rpe"] }
        public var exercise: Exercise { __data["exercise"] }

        /// WhiteboardImport.AsGenerationStrengthSet.Exercise
        ///
        /// Parent Type: `HIITExercise`
        public struct Exercise: WodAiAPI.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.HIITExercise }
          public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("name", String.self),
            .field("muscleGroups", String.self),
            .field("videoUrl", String?.self),
          ] }

          public var name: String { __data["name"] }
          public var muscleGroups: String { __data["muscleGroups"] }
          public var videoUrl: String? { __data["videoUrl"] }
        }
      }

      /// WhiteboardImport.AsGenerationDraftHiitBlock
      ///
      /// Parent Type: `GenerationDraftHiitBlock`
      public struct AsGenerationDraftHiitBlock: WodAiAPI.InlineFragment {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public typealias RootEntityType = WhiteboardImportSubscription.Data.WhiteboardImport
        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.GenerationDraftHiitBlock }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("order", Int.self),
          .field("name", String.self),
          .field("format", String.self),
          .field("displayText", String.self),
          .field("stimulus", String.self),
        ] }

        public var order: Int { __data["order"] }
        public var name: String { __data["name"] }
        public var format: String { __data["format"] }
        public var displayText: String { __data["displayText"] }
        public var stimulus: String { __data["stimulus"] }
      }

      /// WhiteboardImport.AsGenerationComplete
      ///
      /// Parent Type: `GenerationComplete`
      public struct AsGenerationComplete: WodAiAPI.InlineFragment {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public typealias RootEntityType = WhiteboardImportSubscription.Data.WhiteboardImport
        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.GenerationComplete }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("workout", Workout.self),
        ] }

        public var workout: Workout { __data["workout"] }

        /// WhiteboardImport.AsGenerationComplete.Workout
        ///
        /// Parent Type: `Workout`
        public struct Workout: WodAiAPI.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Workout }
          public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .fragment(SessionDetails.self),
          ] }

          public var id: String { __data["id"] }
          public var name: String { __data["name"] }
          public var description: String { __data["description"] }
          public var stimulus: String? { __data["stimulus"] }
          public var coaching: String? { __data["coaching"] }
          public var scheduledDate: WodAiAPI.DateTime { __data["scheduledDate"] }
          public var source: GraphQLEnum<WodAiAPI.WorkoutSource> { __data["source"] }
          public var optional: Bool { __data["optional"] }
          public var blocks: [Block] { __data["blocks"] }

          public struct Fragments: FragmentContainer {
            public let __data: DataDict
            public init(_dataDict: DataDict) { __data = _dataDict }

            public var sessionDetails: SessionDetails { _toFragment() }
          }

          public typealias Block = SessionDetails.Block
        }
      }

      /// WhiteboardImport.AsGenerationFailed
      ///
      /// Parent Type: `GenerationFailed`
      public struct AsGenerationFailed: WodAiAPI.InlineFragment {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public typealias RootEntityType = WhiteboardImportSubscription.Data.WhiteboardImport
        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.GenerationFailed }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("message", String.self),
        ] }

        public var message: String { __data["message"] }
      }
    }
  }
}
