module API exposing (..)

import Http
import Msg exposing (Msg(..))
import Decoders exposing (clustersDecoder)


getClusters : String -> Cmd Msg
getClusters baseUrl =
    clustersDecoder
        |> Http.get (baseUrl ++ "/api/clusters/")
        |> Http.send GotClusters
