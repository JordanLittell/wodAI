// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class UpdateUserMutation: GraphQLMutation {
  public static let operationName: String = "UpdateUser"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"mutation UpdateUser($updateUserId: Int!, $input: UpdateUserInput!) { updateUser(id: $updateUserId, input: $input) { __typename age fitnessLevel gender goal weight { __typename value unit } height { __typename value unit } } }"#
    ))

  public var updateUserId: Int
  public var input: UpdateUserInput

  public init(
    updateUserId: Int,
    input: UpdateUserInput
  ) {
    self.updateUserId = updateUserId
    self.input = input
  }

  public var __variables: Variables? { [
    "updateUserId": updateUserId,
    "input": input
  ] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("updateUser", UpdateUser.self, arguments: [
        "id": .variable("updateUserId"),
        "input": .variable("input")
      ]),
    ] }

    public var updateUser: UpdateUser { __data["updateUser"] }

    /// UpdateUser
    ///
    /// Parent Type: `User`
    public struct UpdateUser: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.User }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("age", Int?.self),
        .field("fitnessLevel", GraphQLEnum<WodAiAPI.FitnessLevel>.self),
        .field("gender", GraphQLEnum<WodAiAPI.Gender>?.self),
        .field("goal", String?.self),
        .field("weight", Weight?.self),
        .field("height", Height?.self),
      ] }

      public var age: Int? { __data["age"] }
      public var fitnessLevel: GraphQLEnum<WodAiAPI.FitnessLevel> { __data["fitnessLevel"] }
      public var gender: GraphQLEnum<WodAiAPI.Gender>? { __data["gender"] }
      public var goal: String? { __data["goal"] }
      public var weight: Weight? { __data["weight"] }
      public var height: Height? { __data["height"] }

      /// UpdateUser.Weight
      ///
      /// Parent Type: `WeightMeasurement`
      public struct Weight: WodAiAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.WeightMeasurement }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("value", Double.self),
          .field("unit", GraphQLEnum<WodAiAPI.WeightUnit>.self),
        ] }

        public var value: Double { __data["value"] }
        public var unit: GraphQLEnum<WodAiAPI.WeightUnit> { __data["unit"] }
      }

      /// UpdateUser.Height
      ///
      /// Parent Type: `HeightMeasurement`
      public struct Height: WodAiAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.HeightMeasurement }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("value", Double.self),
          .field("unit", GraphQLEnum<WodAiAPI.HeightUnit>.self),
        ] }

        public var value: Double { __data["value"] }
        public var unit: GraphQLEnum<WodAiAPI.HeightUnit> { __data["unit"] }
      }
    }
  }
}
