module API exposing (..)

import Http
import RemoteData
import Msg exposing (Msg(..))
import Decoders exposing (clusterDecoder)


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
