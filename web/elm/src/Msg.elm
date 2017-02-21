module Msg exposing (Msg(..))

import Http
import Routing
import Navigation
import Phoenix.Socket
import Json.Encode as Encode
import Types exposing (Service, Cluster)


type Msg
    = NavigateTo (Maybe Routing.Route)
    | UrlChange Navigation.Location
    | OpenSideMenu
    | CloseSideMenu
    | PhoenixMsg (Phoenix.Socket.Msg Msg)
    | ReceiveServices Encode.Value
    | ReceiveServicesInitialState Encode.Value
    | ReceiveDockerEvent Encode.Value
    | GetService String
    | GotService (Result Http.Error Service)
    | GetClusters
    | GotClusters (Result Http.Error (List Cluster))
    | ActivateCluster String
    | ActivatedCluster (Result Http.Error (List Cluster))
