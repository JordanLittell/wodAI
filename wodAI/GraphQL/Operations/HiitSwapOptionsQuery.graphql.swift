// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class HiitSwapOptionsQuery: GraphQLQuery {
  public static let operationName: String = "HiitSwapOptions"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "4679f28159e69ed54c7182b1b1135cfb23bc238696f33a049353c82875d92574",
    definition: .init(
      #"query HiitSwapOptions($pieceId: Int!) { hiitSwapOptions(pieceId: $pieceId) { __typename line partId options { __typename exercise { __typename id name patterns } amount amountUnit max load loadUnit } } }"#
    ))

  public var pieceId: Int

  public init(pieceId: Int) {
    self.pieceId = pieceId
  }

  public var __variables: Variables? { ["pieceId": pieceId] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("hiitSwapOptions", [HiitSwapOption].self, arguments: ["pieceId": .variable("pieceId")]),
    ] }

    public var hiitSwapOptions: [HiitSwapOption] { __data["hiitSwapOptions"] }

    /// HiitSwapOption
    ///
    /// Parent Type: `HIITLineSwapOptions`
    public struct HiitSwapOption: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.HIITLineSwapOptions }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("line", Int.self),
        .field("partId", Int?.self),
        .field("options", [Option].self),
      ] }

      public var line: Int { __data["line"] }
      public var partId: Int? { __data["partId"] }
      public var options: [Option] { __data["options"] }

      /// HiitSwapOption.Option
      ///
      /// Parent Type: `HIITSwapOption`
      public struct Option: WodAiAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.HIITSwapOption }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("exercise", Exercise.self),
          .field("amount", Double?.self),
          .field("amountUnit", GraphQLEnum<WodAiAPI.AmountUnit>.self),
          .field("max", Bool.self),
          .field("load", Double?.self),
          .field("loadUnit", GraphQLEnum<WodAiAPI.LoadUnit>?.self),
        ] }

        public var exercise: Exercise { __data["exercise"] }
        public var amount: Double? { __data["amount"] }
        public var amountUnit: GraphQLEnum<WodAiAPI.AmountUnit> { __data["amountUnit"] }
        public var max: Bool { __data["max"] }
        public var load: Double? { __data["load"] }
        public var loadUnit: GraphQLEnum<WodAiAPI.LoadUnit>? { __data["loadUnit"] }

        /// HiitSwapOption.Option.Exercise
        ///
        /// Parent Type: `HIITExercise`
        public struct Exercise: WodAiAPI.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.HIITExercise }
          public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", Int.self),
            .field("name", String.self),
            .field("patterns", String.self),
          ] }

          public var id: Int { __data["id"] }
          public var name: String { __data["name"] }
          public var patterns: String { __data["patterns"] }
        }
      }
    }
  }
}
