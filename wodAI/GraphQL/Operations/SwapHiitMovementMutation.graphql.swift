// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class SwapHiitMovementMutation: GraphQLMutation {
  public static let operationName: String = "SwapHiitMovement"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "84879942f0a5fe694ef0063ca69a6b2940b062f42fed9b7a632782b2b317c16a",
    definition: .init(
      #"mutation SwapHiitMovement($pieceId: Int!, $line: Int!, $partId: Int, $exerciseId: Int!) { swapHiitMovement( pieceId: $pieceId line: $line partId: $partId exerciseId: $exerciseId ) { __typename id displayText prescriptions { __typename ...HiitLineFields } } }"#,
      fragments: [HiitLineFields.self]
    ))

  public var pieceId: Int
  public var line: Int
  public var partId: GraphQLNullable<Int>
  public var exerciseId: Int

  public init(
    pieceId: Int,
    line: Int,
    partId: GraphQLNullable<Int>,
    exerciseId: Int
  ) {
    self.pieceId = pieceId
    self.line = line
    self.partId = partId
    self.exerciseId = exerciseId
  }

  public var __variables: Variables? { [
    "pieceId": pieceId,
    "line": line,
    "partId": partId,
    "exerciseId": exerciseId
  ] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("swapHiitMovement", SwapHiitMovement.self, arguments: [
        "pieceId": .variable("pieceId"),
        "line": .variable("line"),
        "partId": .variable("partId"),
        "exerciseId": .variable("exerciseId")
      ]),
    ] }

    public var swapHiitMovement: SwapHiitMovement { __data["swapHiitMovement"] }

    /// SwapHiitMovement
    ///
    /// Parent Type: `HIITWorkout`
    public struct SwapHiitMovement: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.HIITWorkout }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", Int.self),
        .field("displayText", String.self),
        .field("prescriptions", [Prescription].self),
      ] }

      public var id: Int { __data["id"] }
      public var displayText: String { __data["displayText"] }
      public var prescriptions: [Prescription] { __data["prescriptions"] }

      /// SwapHiitMovement.Prescription
      ///
      /// Parent Type: `HIITPrescription`
      public struct Prescription: WodAiAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.HIITPrescription }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .fragment(HiitLineFields.self),
        ] }

        public var line: Int { __data["line"] }
        public var partId: Int? { __data["partId"] }
        public var amount: Double? { __data["amount"] }
        public var amountUnit: GraphQLEnum<WodAiAPI.AmountUnit> { __data["amountUnit"] }
        public var max: Bool { __data["max"] }
        public var load: Double? { __data["load"] }
        public var loadUnit: GraphQLEnum<WodAiAPI.LoadUnit>? { __data["loadUnit"] }
        public var exercise: Exercise { __data["exercise"] }

        public struct Fragments: FragmentContainer {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public var hiitLineFields: HiitLineFields { _toFragment() }
        }

        public typealias Exercise = HiitLineFields.Exercise
      }
    }
  }
}
