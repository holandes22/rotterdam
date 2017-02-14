module Model exposing (Model, initialModel)

import Msg exposing (Msg(..))
import Routing
import Types exposing (..)
import Navigation
import Phoenix.Socket exposing (Socket)


type alias Model =
    { route : Maybe Routing.Route
    , baseUrl : String
    , stateSocket : Socket Msg
    , eventsSocket : Socket Msg
    , services : List Service
    , shownService : Maybe Service
    , events : List DockerEvent
    , clusters : List Cluster
    , clusterStatus : Maybe ClusterStatus
    , sideMenuActive : Bool
    }


initialModel : Navigation.Location -> Socket Msg -> Socket Msg -> Model
initialModel location stateSocket eventsSocket =
    let
        route =
            Routing.routeFromLocation location
    in
        { route = route
        , baseUrl = "http://localhost:4000"
        , stateSocket = stateSocket
        , eventsSocket = stateSocket
        , services = []
        , shownService = Nothing
        , events = []
        , clusters = []
        , clusterStatus = Nothing
        , sideMenuActive = True
        }
