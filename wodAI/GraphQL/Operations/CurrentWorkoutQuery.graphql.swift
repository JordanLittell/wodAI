// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class CurrentWorkoutQuery: GraphQLQuery {
  public static let operationName: String = "CurrentWorkout"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "6e9066a1c223608287679b4a2321e03809d54c4f07a82337366a71eadf9c15bd",
    definition: .init(
      #"query CurrentWorkout { currentWorkout { __typename ...SessionDetails } }"#,
      fragments: [SessionDetails.self]
    ))

  public init() {}

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("currentWorkout", CurrentWorkout?.self),
    ] }

    public var currentWorkout: CurrentWorkout? { __data["currentWorkout"] }

    /// CurrentWorkout
    ///
    /// Parent Type: `Workout`
    public struct CurrentWorkout: WodAiAPI.SelectionSet {
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
