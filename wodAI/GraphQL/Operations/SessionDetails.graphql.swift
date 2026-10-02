// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public struct SessionDetails: WodAiAPI.SelectionSet, Fragment {
  public static var fragmentDefinition: StaticString {
    #"fragment SessionDetails on Workout { __typename id name description stimulus coaching scheduledDate source blocks { __typename order ... on StrengthWorkout { id name stimulus instructions components { __typename id order reps weight rpe completedAt completedReps completedWeight completedRpe exercise { __typename name muscleGroups } } } ... on WorkoutHiitPiece { id completion { __typename id completedAt } hiitWorkout { __typename id name format stimulus displayText constraintType constraintMagnitude timeCap timingScheme { __typename version segments { __typename rounds phases { __typename durationSeconds direction label } } phases { __typename durationSeconds direction label } } } } } }"#
  }

  public let __data: DataDict
  public init(_dataDict: DataDict) { __data = _dataDict }

  public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Workout }
  public static var __selections: [ApolloAPI.Selection] { [
    .field("__typename", String.self),
    .field("id", String.self),
    .field("name", String.self),
    .field("description", String.self),
    .field("stimulus", String?.self),
    .field("coaching", String?.self),
    .field("scheduledDate", WodAiAPI.DateTime.self),
    .field("source", GraphQLEnum<WodAiAPI.WorkoutSource>.self),
    .field("blocks", [Block].self),
  ] }

  public var id: String { __data["id"] }
  public var name: String { __data["name"] }
  public var description: String { __data["description"] }
  public var stimulus: String? { __data["stimulus"] }
  public var coaching: String? { __data["coaching"] }
  public var scheduledDate: WodAiAPI.DateTime { __data["scheduledDate"] }
  public var source: GraphQLEnum<WodAiAPI.WorkoutSource> { __data["source"] }
  public var blocks: [Block] { __data["blocks"] }

  /// Block
  ///
  /// Parent Type: `WorkoutBlock`
  public struct Block: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Interfaces.WorkoutBlock }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("__typename", String.self),
      .field("order", Int.self),
      .inlineFragment(AsStrengthWorkout.self),
      .inlineFragment(AsWorkoutHiitPiece.self),
    ] }

    public var order: Int { __data["order"] }

    public var asStrengthWorkout: AsStrengthWorkout? { _asInlineFragment() }
    public var asWorkoutHiitPiece: AsWorkoutHiitPiece? { _asInlineFragment() }

    /// Block.AsStrengthWorkout
    ///
    /// Parent Type: `StrengthWorkout`
    public struct AsStrengthWorkout: WodAiAPI.InlineFragment {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public typealias RootEntityType = SessionDetails.Block
      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.StrengthWorkout }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("id", Int.self),
        .field("name", String?.self),
        .field("stimulus", String.self),
        .field("instructions", String.self),
        .field("components", [Component].self),
      ] }

      public var id: Int { __data["id"] }
      public var name: String? { __data["name"] }
      public var stimulus: String { __data["stimulus"] }
      public var instructions: String { __data["instructions"] }
      public var components: [Component] { __data["components"] }
      public var order: Int { __data["order"] }

      /// Block.AsStrengthWorkout.Component
      ///
      /// Parent Type: `StrengthComponent`
      public struct Component: WodAiAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.StrengthComponent }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", Int.self),
          .field("order", Int.self),
          .field("reps", Int.self),
          .field("weight", Double?.self),
          .field("rpe", Int?.self),
          .field("completedAt", WodAiAPI.DateTime?.self),
          .field("completedReps", Int?.self),
          .field("completedWeight", Double?.self),
          .field("completedRpe", Int?.self),
          .field("exercise", Exercise.self),
        ] }

        public var id: Int { __data["id"] }
        public var order: Int { __data["order"] }
        public var reps: Int { __data["reps"] }
        public var weight: Double? { __data["weight"] }
        public var rpe: Int? { __data["rpe"] }
        public var completedAt: WodAiAPI.DateTime? { __data["completedAt"] }
        public var completedReps: Int? { __data["completedReps"] }
        public var completedWeight: Double? { __data["completedWeight"] }
        public var completedRpe: Int? { __data["completedRpe"] }
        public var exercise: Exercise { __data["exercise"] }

        /// Block.AsStrengthWorkout.Component.Exercise
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
    }

    /// Block.AsWorkoutHiitPiece
    ///
    /// Parent Type: `WorkoutHiitPiece`
    public struct AsWorkoutHiitPiece: WodAiAPI.InlineFragment {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public typealias RootEntityType = SessionDetails.Block
      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.WorkoutHiitPiece }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("id", Int.self),
        .field("completion", Completion?.self),
        .field("hiitWorkout", HiitWorkout.self),
      ] }

      public var id: Int { __data["id"] }
      public var completion: Completion? { __data["completion"] }
      public var hiitWorkout: HiitWorkout { __data["hiitWorkout"] }
      public var order: Int { __data["order"] }

      /// Block.AsWorkoutHiitPiece.Completion
      ///
      /// Parent Type: `CompletedHIITWorkout`
      public struct Completion: WodAiAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.CompletedHIITWorkout }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", Int.self),
          .field("completedAt", WodAiAPI.DateTime.self),
        ] }

        public var id: Int { __data["id"] }
        public var completedAt: WodAiAPI.DateTime { __data["completedAt"] }
      }

      /// Block.AsWorkoutHiitPiece.HiitWorkout
      ///
      /// Parent Type: `HIITWorkout`
      public struct HiitWorkout: WodAiAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.HIITWorkout }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", Int.self),
          .field("name", String?.self),
          .field("format", String?.self),
          .field("stimulus", String.self),
          .field("displayText", String.self),
          .field("constraintType", String.self),
          .field("constraintMagnitude", Int.self),
          .field("timeCap", Int?.self),
          .field("timingScheme", TimingScheme?.self),
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

        /// Block.AsWorkoutHiitPiece.HiitWorkout.TimingScheme
        ///
        /// Parent Type: `WodTimerConfig`
        public struct TimingScheme: WodAiAPI.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.WodTimerConfig }
          public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("version", Int.self),
            .field("segments", [Segment]?.self),
            .field("phases", [Phase]?.self),
          ] }

          public var version: Int { __data["version"] }
          public var segments: [Segment]? { __data["segments"] }
          public var phases: [Phase]? { __data["phases"] }

          /// Block.AsWorkoutHiitPiece.HiitWorkout.TimingScheme.Segment
          ///
          /// Parent Type: `TimerSegment`
          public struct Segment: WodAiAPI.SelectionSet {
            public let __data: DataDict
            public init(_dataDict: DataDict) { __data = _dataDict }

            public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.TimerSegment }
            public static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("rounds", Int.self),
              .field("phases", [Phase].self),
            ] }

            public var rounds: Int { __data["rounds"] }
            public var phases: [Phase] { __data["phases"] }

            /// Block.AsWorkoutHiitPiece.HiitWorkout.TimingScheme.Segment.Phase
            ///
            /// Parent Type: `TimerPhase`
            public struct Phase: WodAiAPI.SelectionSet {
              public let __data: DataDict
              public init(_dataDict: DataDict) { __data = _dataDict }

              public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.TimerPhase }
              public static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("durationSeconds", Int?.self),
                .field("direction", GraphQLEnum<WodAiAPI.PhaseDirection>.self),
                .field("label", String?.self),
              ] }

              public var durationSeconds: Int? { __data["durationSeconds"] }
              public var direction: GraphQLEnum<WodAiAPI.PhaseDirection> { __data["direction"] }
              public var label: String? { __data["label"] }
            }
          }

          /// Block.AsWorkoutHiitPiece.HiitWorkout.TimingScheme.Phase
          ///
          /// Parent Type: `TimerPhase`
          public struct Phase: WodAiAPI.SelectionSet {
            public let __data: DataDict
            public init(_dataDict: DataDict) { __data = _dataDict }

            public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.TimerPhase }
            public static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("durationSeconds", Int?.self),
              .field("direction", GraphQLEnum<WodAiAPI.PhaseDirection>.self),
              .field("label", String?.self),
            ] }

            public var durationSeconds: Int? { __data["durationSeconds"] }
            public var direction: GraphQLEnum<WodAiAPI.PhaseDirection> { __data["direction"] }
            public var label: String? { __data["label"] }
          }
        }
      }
    }
  }
}
