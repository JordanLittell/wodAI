// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class ResetHiitPieceMutation: GraphQLMutation {
  public static let operationName: String = "ResetHiitPiece"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "8a0146a5bd281d003b971f591d51be6e22c7b5f52fbee04d890b0b8fa2c67cc1",
    definition: .init(
      #"mutation ResetHiitPiece($pieceId: Int!) { resetHiitPiece(pieceId: $pieceId) { __typename id displayText modified prescriptions { __typename ...HiitLineFields } } }"#,
      fragments: [HiitLineFields.self]
    ))

  public var pieceId: Int

  public init(pieceId: Int) {
    self.pieceId = pieceId
  }

  public var __variables: Variables? { ["pieceId": pieceId] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("resetHiitPiece", ResetHiitPiece.self, arguments: ["pieceId": .variable("pieceId")]),
    ] }

    public var resetHiitPiece: ResetHiitPiece { __data["resetHiitPiece"] }

    /// ResetHiitPiece
    ///
    /// Parent Type: `HIITWorkout`
    public struct ResetHiitPiece: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.HIITWorkout }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", Int.self),
        .field("displayText", String.self),
        .field("modified", Bool.self),
        .field("prescriptions", [Prescription].self),
      ] }

      public var id: Int { __data["id"] }
      public var displayText: String { __data["displayText"] }
      public var modified: Bool { __data["modified"] }
      public var prescriptions: [Prescription] { __data["prescriptions"] }

      /// ResetHiitPiece.Prescription
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
