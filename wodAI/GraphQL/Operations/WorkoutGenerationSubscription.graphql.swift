// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class WorkoutGenerationSubscription: GraphQLSubscription {
  public static let operationName: String = "WorkoutGeneration"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "664729f90977ea466224c59486494e49cd6a0f73b38a24dca9bf868f778588f1",
    definition: .init(
      #"subscription WorkoutGeneration($request: String, $scheduledDate: String) { workoutGeneration(request: $request, scheduledDate: $scheduledDate) { __typename ... on GenerationSession { name description stimulus } ... on GenerationStrengthBlock { order name instructions } ... on GenerationStrengthSet { order setOrder reps weight rpe exercise { __typename name muscleGroups } } ... on GenerationHiitBlock { order hiitWorkout { __typename ...GeneratedHiitWorkout } } ... on GenerationDraftHiitBlock { order name format displayText stimulus } ... on GenerationComplete { workout { __typename ...SessionDetails } } ... on GenerationFailed { message } } }"#,
      fragments: [GeneratedHiitWorkout.self, SessionDetails.self]
    ))

  public var request: GraphQLNullable<String>
  public var scheduledDate: GraphQLNullable<String>

  public init(
    request: GraphQLNullable<String>,
    scheduledDate: GraphQLNullable<String>
  ) {
    self.request = request
    self.scheduledDate = scheduledDate
  }

  public var __variables: Variables? { [
    "request": request,
    "scheduledDate": scheduledDate
  ] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Subscription }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("workoutGeneration", WorkoutGeneration.self, arguments: [
        "request": .variable("request"),
        "scheduledDate": .variable("scheduledDate")
      ]),
    ] }

    public var workoutGeneration: WorkoutGeneration { __data["workoutGeneration"] }

    /// WorkoutGeneration
    ///
    /// Parent Type: `WorkoutGenerationEvent`
    public struct WorkoutGeneration: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Unions.WorkoutGenerationEvent }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .inlineFragment(AsGenerationSession.self),
        .inlineFragment(AsGenerationStrengthBlock.self),
        .inlineFragment(AsGenerationStrengthSet.self),
        .inlineFragment(AsGenerationHiitBlock.self),
        .inlineFragment(AsGenerationDraftHiitBlock.self),
        .inlineFragment(AsGenerationComplete.self),
        .inlineFragment(AsGenerationFailed.self),
      ] }

      public var asGenerationSession: AsGenerationSession? { _asInlineFragment() }
      public var asGenerationStrengthBlock: AsGenerationStrengthBlock? { _asInlineFragment() }
      public var asGenerationStrengthSet: AsGenerationStrengthSet? { _asInlineFragment() }
      public var asGenerationHiitBlock: AsGenerationHiitBlock? { _asInlineFragment() }
      public var asGenerationDraftHiitBlock: AsGenerationDraftHiitBlock? { _asInlineFragment() }
      public var asGenerationComplete: AsGenerationComplete? { _asInlineFragment() }
      public var asGenerationFailed: AsGenerationFailed? { _asInlineFragment() }

      /// WorkoutGeneration.AsGenerationSession
      ///
      /// Parent Type: `GenerationSession`
      public struct AsGenerationSession: WodAiAPI.InlineFragment {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public typealias RootEntityType = WorkoutGenerationSubscription.Data.WorkoutGeneration
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

      /// WorkoutGeneration.AsGenerationStrengthBlock
      ///
      /// Parent Type: `GenerationStrengthBlock`
      public struct AsGenerationStrengthBlock: WodAiAPI.InlineFragment {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public typealias RootEntityType = WorkoutGenerationSubscription.Data.WorkoutGeneration
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

      /// WorkoutGeneration.AsGenerationStrengthSet
      ///
      /// Parent Type: `GenerationStrengthSet`
      public struct AsGenerationStrengthSet: WodAiAPI.InlineFragment {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public typealias RootEntityType = WorkoutGenerationSubscription.Data.WorkoutGeneration
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

        /// WorkoutGeneration.AsGenerationStrengthSet.Exercise
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
          ] }

          public var name: String { __data["name"] }
          public var muscleGroups: String { __data["muscleGroups"] }
        }
      }

      /// WorkoutGeneration.AsGenerationHiitBlock
      ///
      /// Parent Type: `GenerationHiitBlock`
      public struct AsGenerationHiitBlock: WodAiAPI.InlineFragment {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public typealias RootEntityType = WorkoutGenerationSubscription.Data.WorkoutGeneration
        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.GenerationHiitBlock }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("order", Int.self),
          .field("hiitWorkout", HiitWorkout.self),
        ] }

        public var order: Int { __data["order"] }
        public var hiitWorkout: HiitWorkout { __data["hiitWorkout"] }

        /// WorkoutGeneration.AsGenerationHiitBlock.HiitWorkout
        ///
        /// Parent Type: `HIITWorkout`
        public struct HiitWorkout: WodAiAPI.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.HIITWorkout }
          public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .fragment(GeneratedHiitWorkout.self),
          ] }

          public var id: Int { __data["id"] }
          public var name: String? { __data["name"] }
          public var format: String? { __data["format"] }
          public var stimulus: String { __data["stimulus"] }
          public var displayText: String { __data["displayText"] }
          public var constraintType: String { __data["constraintType"] }
          public var constraintMagnitude: Int { __data["constraintMagnitude"] }
          public var timeCap: Int? { __data["timeCap"] }
          public var timingScheme: TimingScheme? { __data["timingScheme"] }

          public struct Fragments: FragmentContainer {
            public let __data: DataDict
            public init(_dataDict: DataDict) { __data = _dataDict }

            public var generatedHiitWorkout: GeneratedHiitWorkout { _toFragment() }
          }

          public typealias TimingScheme = GeneratedHiitWorkout.TimingScheme
        }
      }

      /// WorkoutGeneration.AsGenerationDraftHiitBlock
      ///
      /// Parent Type: `GenerationDraftHiitBlock`
      public struct AsGenerationDraftHiitBlock: WodAiAPI.InlineFragment {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public typealias RootEntityType = WorkoutGenerationSubscription.Data.WorkoutGeneration
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

      /// WorkoutGeneration.AsGenerationComplete
      ///
      /// Parent Type: `GenerationComplete`
      public struct AsGenerationComplete: WodAiAPI.InlineFragment {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public typealias RootEntityType = WorkoutGenerationSubscription.Data.WorkoutGeneration
        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.GenerationComplete }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("workout", Workout.self),
        ] }

        public var workout: Workout { __data["workout"] }

        /// WorkoutGeneration.AsGenerationComplete.Workout
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
          public var blocks: [Block] { __data["blocks"] }

          public struct Fragments: FragmentContainer {
            public let __data: DataDict
            public init(_dataDict: DataDict) { __data = _dataDict }

            public var sessionDetails: SessionDetails { _toFragment() }
          }

          public typealias Block = SessionDetails.Block
        }
      }

      /// WorkoutGeneration.AsGenerationFailed
      ///
      /// Parent Type: `GenerationFailed`
      public struct AsGenerationFailed: WodAiAPI.InlineFragment {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public typealias RootEntityType = WorkoutGenerationSubscription.Data.WorkoutGeneration
        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.GenerationFailed }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("message", String.self),
        ] }

        public var message: String { __data["message"] }
      }
    }
  }
}
