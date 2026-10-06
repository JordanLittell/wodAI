// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public struct WhiteboardImportInput: InputObject {
  public private(set) var __data: InputDict

  public init(_ data: InputDict) {
    __data = data
  }

  public init(
    imageJpegBase64: String,
    recognizedText: GraphQLNullable<String> = nil,
    scheduledDate: String
  ) {
    __data = InputDict([
      "imageJpegBase64": imageJpegBase64,
      "recognizedText": recognizedText,
      "scheduledDate": scheduledDate
    ])
  }

  public var imageJpegBase64: String {
    get { __data["imageJpegBase64"] }
    set { __data["imageJpegBase64"] = newValue }
  }

  public var recognizedText: GraphQLNullable<String> {
    get { __data["recognizedText"] }
    set { __data["recognizedText"] = newValue }
  }

  public var scheduledDate: String {
    get { __data["scheduledDate"] }
    set { __data["scheduledDate"] = newValue }
  }
}
