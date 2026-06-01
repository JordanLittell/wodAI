// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public struct ProvisionUserInput: InputObject {
  public private(set) var __data: InputDict

  public init(_ data: InputDict) {
    __data = data
  }

  public init(
    age: Int,
    heightInches: Int,
    weight: Int,
    gender: GraphQLEnum<WodAiAPI.Gender>,
    fitnessLevel: GraphQLEnum<WodAiAPI.FitnessLevel>,
    workoutDuration: Int,
    benchmarks: [WodAiAPI.BenchmarkInput],
    injuries: GraphQLNullable<[WodAiAPI.InjuryInput]> = nil,
    availableEquipment: [GraphQLEnum<WodAiAPI.FitnessEquipment>],
    sessionDurationMinutes: Int,
    restDays: [GraphQLEnum<WodAiAPI.RestDay>]
  ) {
    __data = InputDict([
      "age": age,
      "heightInches": heightInches,
      "weight": weight,
      "gender": gender,
      "fitnessLevel": fitnessLevel,
      "workoutDuration": workoutDuration,
      "benchmarks": benchmarks,
      "injuries": injuries,
      "availableEquipment": availableEquipment,
      "sessionDurationMinutes": sessionDurationMinutes,
      "restDays": restDays
    ])
  }

  public var age: Int {
    get { __data["age"] }
    set { __data["age"] = newValue }
  }

  public var heightInches: Int {
    get { __data["heightInches"] }
    set { __data["heightInches"] = newValue }
  }

  public var weight: Int {
    get { __data["weight"] }
    set { __data["weight"] = newValue }
  }

  public var gender: GraphQLEnum<WodAiAPI.Gender> {
    get { __data["gender"] }
    set { __data["gender"] = newValue }
  }

  public var fitnessLevel: GraphQLEnum<WodAiAPI.FitnessLevel> {
    get { __data["fitnessLevel"] }
    set { __data["fitnessLevel"] = newValue }
  }

  public var workoutDuration: Int {
    get { __data["workoutDuration"] }
    set { __data["workoutDuration"] = newValue }
  }

  public var benchmarks: [WodAiAPI.BenchmarkInput] {
    get { __data["benchmarks"] }
    set { __data["benchmarks"] = newValue }
  }

  public var injuries: GraphQLNullable<[WodAiAPI.InjuryInput]> {
    get { __data["injuries"] }
    set { __data["injuries"] = newValue }
  }

  public var availableEquipment: [GraphQLEnum<WodAiAPI.FitnessEquipment>] {
    get { __data["availableEquipment"] }
    set { __data["availableEquipment"] = newValue }
  }

  public var sessionDurationMinutes: Int {
    get { __data["sessionDurationMinutes"] }
    set { __data["sessionDurationMinutes"] = newValue }
  }

  public var restDays: [GraphQLEnum<WodAiAPI.RestDay>] {
    get { __data["restDays"] }
    set { __data["restDays"] = newValue }
  }
}
