// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public protocol SelectionSet: ApolloAPI.SelectionSet & ApolloAPI.RootSelectionSet
where Schema == WodAiAPI.SchemaMetadata {}

public protocol InlineFragment: ApolloAPI.SelectionSet & ApolloAPI.InlineFragment
where Schema == WodAiAPI.SchemaMetadata {}

public protocol MutableSelectionSet: ApolloAPI.MutableRootSelectionSet
where Schema == WodAiAPI.SchemaMetadata {}

public protocol MutableInlineFragment: ApolloAPI.MutableSelectionSet & ApolloAPI.InlineFragment
where Schema == WodAiAPI.SchemaMetadata {}

public enum SchemaMetadata: ApolloAPI.SchemaMetadata {
  public static let configuration: any ApolloAPI.SchemaConfiguration.Type = SchemaConfiguration.self

  public static func objectType(forTypename typename: String) -> ApolloAPI.Object? {
    switch typename {
    case "AuthPayload": return WodAiAPI.Objects.AuthPayload
    case "CategoricalStat": return WodAiAPI.Objects.CategoricalStat
    case "CategoryPoint": return WodAiAPI.Objects.CategoryPoint
    case "CompletedHIITWorkout": return WodAiAPI.Objects.CompletedHIITWorkout
    case "CompletedStrengthWorkout": return WodAiAPI.Objects.CompletedStrengthWorkout
    case "CompletedWodsResponse": return WodAiAPI.Objects.CompletedWodsResponse
    case "Component": return WodAiAPI.Objects.Component
    case "Equipment": return WodAiAPI.Objects.Equipment
    case "GenerationComplete": return WodAiAPI.Objects.GenerationComplete
    case "GenerationDraftHiitBlock": return WodAiAPI.Objects.GenerationDraftHiitBlock
    case "GenerationFailed": return WodAiAPI.Objects.GenerationFailed
    case "GenerationHiitBlock": return WodAiAPI.Objects.GenerationHiitBlock
    case "GenerationSession": return WodAiAPI.Objects.GenerationSession
    case "GenerationStrengthBlock": return WodAiAPI.Objects.GenerationStrengthBlock
    case "GenerationStrengthSet": return WodAiAPI.Objects.GenerationStrengthSet
    case "GymPreset": return WodAiAPI.Objects.GymPreset
    case "GymProfile": return WodAiAPI.Objects.GymProfile
    case "HIITExercise": return WodAiAPI.Objects.HIITExercise
    case "HIITPaginatedResponse": return WodAiAPI.Objects.HIITPaginatedResponse
    case "HIITSession": return WodAiAPI.Objects.HIITSession
    case "HIITWorkout": return WodAiAPI.Objects.HIITWorkout
    case "HeartRateSample": return WodAiAPI.Objects.HeartRateSample
    case "HeartRateSummary": return WodAiAPI.Objects.HeartRateSummary
    case "Mutation": return WodAiAPI.Objects.Mutation
    case "Query": return WodAiAPI.Objects.Query
    case "RecoveryStatus": return WodAiAPI.Objects.RecoveryStatus
    case "SavedHIITWorkout": return WodAiAPI.Objects.SavedHIITWorkout
    case "SeriesPoint": return WodAiAPI.Objects.SeriesPoint
    case "SeriesStat": return WodAiAPI.Objects.SeriesStat
    case "SkillDomain": return WodAiAPI.Objects.SkillDomain
    case "SkillLadder": return WodAiAPI.Objects.SkillLadder
    case "SkillRung": return WodAiAPI.Objects.SkillRung
    case "StrengthBenchmark": return WodAiAPI.Objects.StrengthBenchmark
    case "StrengthComponent": return WodAiAPI.Objects.StrengthComponent
    case "StrengthWorkout": return WodAiAPI.Objects.StrengthWorkout
    case "Subscription": return WodAiAPI.Objects.Subscription
    case "Tag": return WodAiAPI.Objects.Tag
    case "TagFacet": return WodAiAPI.Objects.TagFacet
    case "TimerPhase": return WodAiAPI.Objects.TimerPhase
    case "TimerSegment": return WodAiAPI.Objects.TimerSegment
    case "User": return WodAiAPI.Objects.User
    case "WeeklyPlanJob": return WodAiAPI.Objects.WeeklyPlanJob
    case "WodTimerConfig": return WodAiAPI.Objects.WodTimerConfig
    case "Workout": return WodAiAPI.Objects.Workout
    case "WorkoutHiitPiece": return WodAiAPI.Objects.WorkoutHiitPiece
    default: return nil
    }
  }
}

public enum Objects {}
public enum Interfaces {}
public enum Unions {}
