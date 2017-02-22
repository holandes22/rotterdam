module Main exposing (..)

import Navigation
import View
import Update
import Model exposing (Model)
import Msg exposing (Msg(..))
import Json.Encode as Encode
import Phoenix.Socket
import Phoenix.Channel
import Routing
import Types exposing (Cluster)
import API


main : Program Flags Model Msg
main =
    Navigation.programWithFlags UrlChange
        { init = init
        , update = Update.update
        , view = View.view
        , subscriptions = subscriptions
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Phoenix.Socket.listen model.stateSocket PhoenixMsg
        , Phoenix.Socket.listen model.eventsSocket PhoenixMsg
        ]


socketServer : String
socketServer =
    "ws://localhost:4000/socket/websocket"


socket : Phoenix.Socket.Socket Msg
socket =
    Phoenix.Socket.init socketServer
        |> Phoenix.Socket.withDebug
        |> Phoenix.Socket.on "services" "state:docker" ReceiveServices
        |> Phoenix.Socket.on "event" "events:docker" ReceiveDockerEvent


joinStateChannel : Phoenix.Socket.Socket Msg -> ( Phoenix.Socket.Socket Msg, Cmd (Phoenix.Socket.Msg Msg) )
joinStateChannel socket =
    let
        payload =
            Encode.object [ ( "init", Encode.string "services" ) ]

        channel =
            Phoenix.Channel.init "state:docker"
                |> Phoenix.Channel.withPayload payload
                |> Phoenix.Channel.onJoin ReceiveServicesInitialState

        ( phxSocket, phxCmd ) =
            Phoenix.Socket.join channel socket
    in
        ( phxSocket, phxCmd )


joinEventsChannel : Phoenix.Socket.Socket Msg -> ( Phoenix.Socket.Socket Msg, Cmd (Phoenix.Socket.Msg Msg) )
joinEventsChannel socket =
    let
        channel =
            Phoenix.Channel.init "events:docker"

        ( phxSocket, phxCmd ) =
            Phoenix.Socket.join channel socket
    in
        ( phxSocket, phxCmd )


type alias Flags =
    { cluster : Cluster }


init : Flags -> Navigation.Location -> ( Model, Cmd Msg )
init flags location =
    let
        ( stateSocket, stateCmd ) =
            joinStateChannel socket

        ( eventsSocket, eventsCmd ) =
            joinEventsChannel socket

        route =
            Routing.routeFromLocation location

        initialModel =
            Model.initialModel route stateSocket eventsSocket flags.cluster

        cmds =
            [ (Cmd.map PhoenixMsg stateCmd)
            , (Cmd.map PhoenixMsg eventsCmd)
            ]
                ++ initialCmds route initialModel
    in
        ( initialModel
        , Cmd.batch cmds
        )


initialCmds : Maybe Routing.Route -> Model -> List (Cmd Msg)
initialCmds route model =
    case route of
        Just (Routing.Clusters) ->
            [ API.getCluster model.baseUrl ]

        _ ->
            [ Cmd.none ]
