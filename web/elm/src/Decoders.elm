module Decoders exposing (..)

import Json.Decode as Decode
import Json.Decode.Extra exposing ((|:))
import Types exposing (..)


serviceDecoder : Decode.Decoder Service
serviceDecoder =
    Decode.succeed Service
        |: (Decode.field "name" Decode.string)
        |: (Decode.field "replicas" Decode.int)
        |: (Decode.field "image" Decode.string)
        |: (Decode.field "id" Decode.string)


servicesDecoder : Decode.Decoder (List Service)
servicesDecoder =
    Decode.list serviceDecoder


dockerEventDecoder : Decode.Decoder DockerEvent
dockerEventDecoder =
    Decode.succeed DockerEvent
        |: (Decode.field "node_label" Decode.string)
        |: (Decode.field "container" Decode.string)
        |: (Decode.field "type" Decode.string)
        |: (Decode.field "action" Decode.string)
        |: (Decode.field "service_name" Decode.string)
        |: (Decode.field "service_id" Decode.string)
        |: (Decode.field "image" Decode.string)
        |: (Decode.field "time" Decode.int)


clusterDecoder : Decode.Decoder Cluster
clusterDecoder =
    Decode.succeed Cluster
        |: (Decode.field "id" Decode.string)
        |: (Decode.field "label" Decode.string)
        |: (Decode.field "active" Decode.bool)
        |: (Decode.field "nodes" (Decode.list nodeDecoder))


clustersDecoder : Decode.Decoder (List Cluster)
clustersDecoder =
    Decode.list clusterDecoder


nodeDecoder : Decode.Decoder Node
nodeDecoder =
    Decode.succeed Node
        |: (Decode.field "id" Decode.string)
        |: (Decode.field "label" Decode.string)
        |: (Decode.field "role" Decode.string)
        |: (Decode.field "host" Decode.string)
        |: (Decode.field "status" Decode.string)
