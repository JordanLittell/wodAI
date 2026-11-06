// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class AdjustHiitLineMutation: GraphQLMutation {
  public static let operationName: String = "AdjustHiitLine"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "2c9aee8459a93fd0db26beba07e451428a39e01e1fc5901cbccbcdbb262eddc1",
    definition: .init(
      #"mutation AdjustHiitLine($pieceId: Int!, $line: Int!, $partId: Int, $amount: Float, $load: Float, $clearLoad: Boolean) { adjustHiitLine( pieceId: $pieceId line: $line partId: $partId amount: $amount load: $load clearLoad: $clearLoad ) { __typename id displayText modified prescriptions { __typename ...HiitLineFields } } }"#,
      fragments: [HiitLineFields.self]
    ))

  public var pieceId: Int
  public var line: Int
  public var partId: GraphQLNullable<Int>
  public var amount: GraphQLNullable<Double>
  public var load: GraphQLNullable<Double>
  public var clearLoad: GraphQLNullable<Bool>

  public init(
    pieceId: Int,
    line: Int,
    partId: GraphQLNullable<Int>,
    amount: GraphQLNullable<Double>,
    load: GraphQLNullable<Double>,
    clearLoad: GraphQLNullable<Bool>
  ) {
    self.pieceId = pieceId
    self.line = line
    self.partId = partId
    self.amount = amount
    self.load = load
    self.clearLoad = clearLoad
  }

  public var __variables: Variables? { [
    "pieceId": pieceId,
    "line": line,
    "partId": partId,
    "amount": amount,
    "load": load,
    "clearLoad": clearLoad
  ] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("adjustHiitLine", AdjustHiitLine.self, arguments: [
        "pieceId": .variable("pieceId"),
        "line": .variable("line"),
        "partId": .variable("partId"),
        "amount": .variable("amount"),
        "load": .variable("load"),
        "clearLoad": .variable("clearLoad")
      ]),
    ] }

    public var adjustHiitLine: AdjustHiitLine { __data["adjustHiitLine"] }

    /// AdjustHiitLine
    ///
    /// Parent Type: `HIITWorkout`
    public struct AdjustHiitLine: WodAiAPI.SelectionSet {
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

      /// AdjustHiitLine.Prescription
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
