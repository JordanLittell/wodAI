// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class GenerateWorkoutMutation: GraphQLMutation {
  public static let operationName: String = "GenerateWorkout"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "22c105f6377af6a862a8ad99229a82486c5666d7b6c110bbb804a5d9adb6e8a0",
    definition: .init(
      #"mutation GenerateWorkout { generate { __typename ...SessionDetails } }"#,
      fragments: [SessionDetails.self]
    ))

  public init() {}

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("generate", Generate.self),
    ] }

    public var generate: Generate { __data["generate"] }

    /// Generate
    ///
    /// Parent Type: `Workout`
    public struct Generate: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Workout }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .fragment(SessionDetails.self),
      ] }

      public var id: String { __data["id"] }
      public var name: String { __data["name"] }
      public var description: String { __data["description"] }
      public var stimulus: String? { __data["stimulus"] }
      public var coaching: String? { __data["coaching"] }
      public var scheduledDate: WodAiAPI.DateTime { __data["scheduledDate"] }
      public var source: GraphQLEnum<WodAiAPI.WorkoutSource> { __data["source"] }
      public var optional: Bool { __data["optional"] }
      public var blocks: [Block] { __data["blocks"] }

      public struct Fragments: FragmentContainer {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public var sessionDetails: SessionDetails { _toFragment() }
      }

      public typealias Block = SessionDetails.Block
    }
  }
}
