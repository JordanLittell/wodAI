// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class AppendSensorFramesMutation: GraphQLMutation {
  public static let operationName: String = "AppendSensorFrames"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "95dd705ced295368a28cc199fb79882320e09265daf35f8ae7193a8ec754ef75",
    definition: .init(
      #"mutation AppendSensorFrames($sessionId: ID!, $frames: [SensorFrameInput!]!) { appendSensorFrames(sessionId: $sessionId, frames: $frames) }"#
    ))

  public var sessionId: WodAiAPI.ID
  public var frames: [WodAiAPI.SensorFrameInput]

  public init(
    sessionId: WodAiAPI.ID,
    frames: [WodAiAPI.SensorFrameInput]
  ) {
    self.sessionId = sessionId
    self.frames = frames
  }

  public var __variables: Variables? { [
    "sessionId": sessionId,
    "frames": frames
  ] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("appendSensorFrames", Bool.self, arguments: [
        "sessionId": .variable("sessionId"),
        "frames": .variable("frames")
      ]),
    ] }

    public var appendSensorFrames: Bool { __data["appendSensorFrames"] }
  }
}
