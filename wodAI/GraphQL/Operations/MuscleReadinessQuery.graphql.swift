// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class MuscleReadinessQuery: GraphQLQuery {
  public static let operationName: String = "MuscleReadiness"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "10e089a6bfd87b6d244bdee13ba32c5d4a5640c4803721e92565dd64dd2133bf",
    definition: .init(
      #"query MuscleReadiness { muscleReadiness { __typename slug name fatigue readyAt } }"#
    ))

  public init() {}

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("muscleReadiness", [MuscleReadiness].self),
    ] }

    public var muscleReadiness: [MuscleReadiness] { __data["muscleReadiness"] }

    /// MuscleReadiness
    ///
    /// Parent Type: `RegionReadiness`
    public struct MuscleReadiness: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.RegionReadiness }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("slug", String.self),
        .field("name", String.self),
        .field("fatigue", Int.self),
        .field("readyAt", WodAiAPI.DateTime?.self),
      ] }

      public var slug: String { __data["slug"] }
      public var name: String { __data["name"] }
      public var fatigue: Int { __data["fatigue"] }
      public var readyAt: WodAiAPI.DateTime? { __data["readyAt"] }
    }
  }
}
