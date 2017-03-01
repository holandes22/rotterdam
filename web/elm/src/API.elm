module API exposing (..)

import Http
import RemoteData
import Msg exposing (Msg(..))
import Decoders exposing (clusterDecoder)
import Encoders exposing (encodeServiceForm)
import Types exposing (ServiceForm)
import Json.Decode exposing (field, string)


getCluster : String -> Cmd Msg
getCluster baseUrl =
    clusterDecoder
        |> Http.get (baseUrl ++ "/api/cluster/")
        |> RemoteData.sendRequest
        |> Cmd.map GotCluster


connectCluster : String -> Cmd Msg
connectCluster baseUrl =
    clusterDecoder
        |> Http.post (baseUrl ++ "/api/cluster/connect") Http.emptyBody
        |> RemoteData.sendRequest
        |> Cmd.map GotCluster


createService : String -> ServiceForm -> Cmd Msg
createService baseUrl serviceForm =
    let
        url =
            baseUrl ++ "/api/services"

        payload =
            Http.jsonBody <| encodeServiceForm serviceForm
    in
        field "ID" string
            |> Http.post url payload
            |> Http.send ServiceCreated
