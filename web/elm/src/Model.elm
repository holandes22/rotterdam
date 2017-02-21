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
    , activeCluster : Maybe Cluster
    , sideMenuActive : Bool
    }


initialModel :
    Maybe Routing.Route
    -> Socket Msg
    -> Socket Msg
    -> Maybe Cluster
    -> Model
initialModel route stateSocket eventsSocket activeCluster =
    { route = route
    , baseUrl = "http://localhost:4000"
    , stateSocket = stateSocket
    , eventsSocket = stateSocket
    , services = []
    , shownService = Nothing
    , events = []
    , clusters = []
    , activeCluster = activeCluster
    , sideMenuActive = True
    }
