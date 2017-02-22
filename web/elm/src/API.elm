module API exposing (..)

import Http
import Msg exposing (Msg(..))
import Decoders exposing (clusterDecoder)


getCluster : String -> Cmd Msg
getCluster baseUrl =
    clusterDecoder
        |> Http.get (baseUrl ++ "/api/cluster/")
        |> Http.send GotCluster
