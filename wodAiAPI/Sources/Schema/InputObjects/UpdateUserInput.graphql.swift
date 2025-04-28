// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public struct UpdateUserInput: InputObject {
  public private(set) var __data: InputDict

  public init(_ data: InputDict) {
    __data = data
  }

  public init(
    firstName: GraphQLNullable<String> = nil,
    lastName: GraphQLNullable<String> = nil,
    email: GraphQLNullable<String> = nil,
    age: GraphQLNullable<Int> = nil,
    gender: GraphQLNullable<GraphQLEnum<Gender>> = nil,
    fitnessLevel: GraphQLNullable<GraphQLEnum<FitnessLevel>> = nil,
    equipment: GraphQLNullable<[GraphQLEnum<FitnessEquipment>]> = nil,
    goal: GraphQLNullable<String> = nil,
    weight: GraphQLNullable<WeightInput> = nil,
    height: GraphQLNullable<HeightInput> = nil
  ) {
    __data = InputDict([
      "firstName": firstName,
      "lastName": lastName,
      "email": email,
      "age": age,
      "gender": gender,
      "fitnessLevel": fitnessLevel,
      "equipment": equipment,
      "goal": goal,
      "weight": weight,
      "height": height
    ])
  }

  public var firstName: GraphQLNullable<String> {
    get { __data["firstName"] }
    set { __data["firstName"] = newValue }
  }

  public var lastName: GraphQLNullable<String> {
    get { __data["lastName"] }
    set { __data["lastName"] = newValue }
  }

  public var email: GraphQLNullable<String> {
    get { __data["email"] }
    set { __data["email"] = newValue }
  }

  public var age: GraphQLNullable<Int> {
    get { __data["age"] }
    set { __data["age"] = newValue }
  }

  public var gender: GraphQLNullable<GraphQLEnum<Gender>> {
    get { __data["gender"] }
    set { __data["gender"] = newValue }
  }

  public var fitnessLevel: GraphQLNullable<GraphQLEnum<FitnessLevel>> {
    get { __data["fitnessLevel"] }
    set { __data["fitnessLevel"] = newValue }
  }

  public var equipment: GraphQLNullable<[GraphQLEnum<FitnessEquipment>]> {
    get { __data["equipment"] }
    set { __data["equipment"] = newValue }
  }

  public var goal: GraphQLNullable<String> {
    get { __data["goal"] }
    set { __data["goal"] = newValue }
  }

  public var weight: GraphQLNullable<WeightInput> {
    get { __data["weight"] }
    set { __data["weight"] = newValue }
  }

  public var height: GraphQLNullable<HeightInput> {
    get { __data["height"] }
    set { __data["height"] = newValue }
  }
}
