// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class MuscleReadinessQuery: GraphQLQuery {
  public static let operationName: String = "MuscleReadiness"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "332e8f7cd668b749fdea41bd0ef465bc1e1bbdac4b048722d6da7f890705d0f7",
    definition: .init(
      #"query MuscleReadiness { muscleReadiness { __typename slug name fatigue readyAt recoveredAt } }"#
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
        .field("recoveredAt", WodAiAPI.DateTime.self),
      ] }

      public var slug: String { __data["slug"] }
      public var name: String { __data["name"] }
      public var fatigue: Int { __data["fatigue"] }
      public var readyAt: WodAiAPI.DateTime? { __data["readyAt"] }
      public var recoveredAt: WodAiAPI.DateTime { __data["recoveredAt"] }
    }
  }
}
