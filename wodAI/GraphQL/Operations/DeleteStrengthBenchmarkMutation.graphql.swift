// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class DeleteStrengthBenchmarkMutation: GraphQLMutation {
  public static let operationName: String = "DeleteStrengthBenchmark"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "77f038a5279e7cd544adf74aac1c92aa955df9cca086104a9493adda0a1ac04f",
    definition: .init(
      #"mutation DeleteStrengthBenchmark($id: Int!) { deleteStrengthBenchmark(id: $id) }"#
    ))

  public var id: Int

  public init(id: Int) {
    self.id = id
  }

  public var __variables: Variables? { ["id": id] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("deleteStrengthBenchmark", Bool.self, arguments: ["id": .variable("id")]),
    ] }

    public var deleteStrengthBenchmark: Bool { __data["deleteStrengthBenchmark"] }
  }
}
