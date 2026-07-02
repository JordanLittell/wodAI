//
//  WodTimerConfig+Apollo.swift
//  wodAI
//
//  Conforms the generated (per-operation) timingScheme selection sets to the
//  engine's structural bridge protocols so they can all feed
//  `WodTimerConfig(fragment:)`.
//

import Foundation
import WodAiAPI

// MARK: - GenerateHiitWorkout

extension GenerateHiitWorkoutMutation.Data.GenerateHiitWorkout.TimingScheme.Segment.Phase: TimingPhaseFragment {}
extension GenerateHiitWorkoutMutation.Data.GenerateHiitWorkout.TimingScheme.Segment: TimingSegmentFragment {}
extension GenerateHiitWorkoutMutation.Data.GenerateHiitWorkout.TimingScheme: TimingSchemeFragment {}

// MARK: - HIITWorkouts

extension HIITWorkoutsQuery.Data.HiitWorkouts.Datum.TimingScheme.Segment.Phase: TimingPhaseFragment {}
extension HIITWorkoutsQuery.Data.HiitWorkouts.Datum.TimingScheme.Segment: TimingSegmentFragment {}
extension HIITWorkoutsQuery.Data.HiitWorkouts.Datum.TimingScheme: TimingSchemeFragment {}

// MARK: - SavedHiitWorkouts

extension SavedHiitWorkoutsQuery.Data.SavedHiitWorkout.Workout.TimingScheme.Segment.Phase: TimingPhaseFragment {}
extension SavedHiitWorkoutsQuery.Data.SavedHiitWorkout.Workout.TimingScheme.Segment: TimingSegmentFragment {}
extension SavedHiitWorkoutsQuery.Data.SavedHiitWorkout.Workout.TimingScheme: TimingSchemeFragment {}
