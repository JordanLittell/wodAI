// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class ImportHealthSnapshotMutation: GraphQLMutation {
  public static let operationName: String = "ImportHealthSnapshot"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "9e9a4929ef6900bddf2add06aa9443bd0ce7c1f2228cfed83077343eb5b69518",
    definition: .init(
      #"mutation ImportHealthSnapshot($input: HealthSnapshotInput!) { importHealthSnapshot(input: $input) { __typename suggestedFitnessLevel reasons } }"#
    ))

  public var input: WodAiAPI.HealthSnapshotInput

  public init(input: WodAiAPI.HealthSnapshotInput) {
    self.input = input
  }

  public var __variables: Variables? { ["input": input] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("importHealthSnapshot", ImportHealthSnapshot.self, arguments: ["input": .variable("input")]),
    ] }

    public var importHealthSnapshot: ImportHealthSnapshot { __data["importHealthSnapshot"] }

    /// ImportHealthSnapshot
    ///
    /// Parent Type: `HealthImportResult`
    public struct ImportHealthSnapshot: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.HealthImportResult }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("suggestedFitnessLevel", GraphQLEnum<WodAiAPI.FitnessLevel>?.self),
        .field("reasons", [String].self),
      ] }

      public var suggestedFitnessLevel: GraphQLEnum<WodAiAPI.FitnessLevel>? { __data["suggestedFitnessLevel"] }
      public var reasons: [String] { __data["reasons"] }
    }
  }
}
