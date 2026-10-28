// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class TrainingMemoryQuery: GraphQLQuery {
  public static let operationName: String = "TrainingMemory"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "b5bf6bed377328465250fb4378411d3781c498d34a81052464625b7b9ed521b4",
    definition: .init(
      #"query TrainingMemory { trainingMemory { __typename focus { __typename ...MemoryItemFields } habits { __typename ...MemoryItemFields } avoid { __typename ...MemoryItemFields } } }"#,
      fragments: [MemoryItemFields.self]
    ))

  public init() {}

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("trainingMemory", TrainingMemory.self),
    ] }

    public var trainingMemory: TrainingMemory { __data["trainingMemory"] }

    /// TrainingMemory
    ///
    /// Parent Type: `TrainingMemory`
    public struct TrainingMemory: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.TrainingMemory }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("focus", Focus?.self),
        .field("habits", [Habit].self),
        .field("avoid", [Avoid].self),
      ] }

      public var focus: Focus? { __data["focus"] }
      public var habits: [Habit] { __data["habits"] }
      public var avoid: [Avoid] { __data["avoid"] }

      /// TrainingMemory.Focus
      ///
      /// Parent Type: `MemoryItem`
      public struct Focus: WodAiAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.MemoryItem }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .fragment(MemoryItemFields.self),
        ] }

        public var id: WodAiAPI.ID { __data["id"] }
        public var kind: GraphQLEnum<WodAiAPI.MemoryItemKind> { __data["kind"] }
        public var text: String { __data["text"] }
        public var startsOn: String? { __data["startsOn"] }
        public var endsOn: String? { __data["endsOn"] }

        public struct Fragments: FragmentContainer {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public var memoryItemFields: MemoryItemFields { _toFragment() }
        }
      }

      /// TrainingMemory.Habit
      ///
      /// Parent Type: `MemoryItem`
      public struct Habit: WodAiAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.MemoryItem }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .fragment(MemoryItemFields.self),
        ] }

        public var id: WodAiAPI.ID { __data["id"] }
        public var kind: GraphQLEnum<WodAiAPI.MemoryItemKind> { __data["kind"] }
        public var text: String { __data["text"] }
        public var startsOn: String? { __data["startsOn"] }
        public var endsOn: String? { __data["endsOn"] }

        public struct Fragments: FragmentContainer {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public var memoryItemFields: MemoryItemFields { _toFragment() }
        }
      }

      /// TrainingMemory.Avoid
      ///
      /// Parent Type: `MemoryItem`
      public struct Avoid: WodAiAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.MemoryItem }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .fragment(MemoryItemFields.self),
        ] }

        public var id: WodAiAPI.ID { __data["id"] }
        public var kind: GraphQLEnum<WodAiAPI.MemoryItemKind> { __data["kind"] }
        public var text: String { __data["text"] }
        public var startsOn: String? { __data["startsOn"] }
        public var endsOn: String? { __data["endsOn"] }

        public struct Fragments: FragmentContainer {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public var memoryItemFields: MemoryItemFields { _toFragment() }
        }
      }
    }
  }
}
