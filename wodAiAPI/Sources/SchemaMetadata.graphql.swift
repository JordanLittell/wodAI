// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public protocol SelectionSet: ApolloAPI.SelectionSet & ApolloAPI.RootSelectionSet
where Schema == WodAiAPI.SchemaMetadata {}

public protocol InlineFragment: ApolloAPI.SelectionSet & ApolloAPI.InlineFragment
where Schema == WodAiAPI.SchemaMetadata {}

public protocol MutableSelectionSet: ApolloAPI.MutableRootSelectionSet
where Schema == WodAiAPI.SchemaMetadata {}

public protocol MutableInlineFragment: ApolloAPI.MutableSelectionSet & ApolloAPI.InlineFragment
where Schema == WodAiAPI.SchemaMetadata {}

public enum SchemaMetadata: ApolloAPI.SchemaMetadata {
  public static let configuration: any ApolloAPI.SchemaConfiguration.Type = SchemaConfiguration.self

  public static func objectType(forTypename typename: String) -> ApolloAPI.Object? {
    switch typename {
    case "AgentMessage": return WodAiAPI.Objects.AgentMessage
    case "AgentResponse": return WodAiAPI.Objects.AgentResponse
    case "AuthPayload": return WodAiAPI.Objects.AuthPayload
    case "CompletedWodsResponse": return WodAiAPI.Objects.CompletedWodsResponse
    case "Component": return WodAiAPI.Objects.Component
    case "Conversation": return WodAiAPI.Objects.Conversation
    case "Equipment": return WodAiAPI.Objects.Equipment
    case "GymProfile": return WodAiAPI.Objects.GymProfile
    case "Mutation": return WodAiAPI.Objects.Mutation
    case "ProvisionUserResponse": return WodAiAPI.Objects.ProvisionUserResponse
    case "Query": return WodAiAPI.Objects.Query
    case "SendAgentMessageResponse": return WodAiAPI.Objects.SendAgentMessageResponse
    case "Subscription": return WodAiAPI.Objects.Subscription
    case "User": return WodAiAPI.Objects.User
    case "Workout": return WodAiAPI.Objects.Workout
    case "WorkoutScheduleResponse": return WodAiAPI.Objects.WorkoutScheduleResponse
    default: return nil
    }
  }
}

public enum Objects {}
public enum Interfaces {}
public enum Unions {}
