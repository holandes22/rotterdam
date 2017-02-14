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
    { activeCluster : Maybe String
    }


init : Flags -> Navigation.Location -> ( Model, Cmd Msg )
init flags location =
    let
        _ =
            Debug.log "FLAGS" flags

        ( stateSocket, stateCmd ) =
            joinStateChannel socket

        ( eventsSocket, eventsCmd ) =
            joinEventsChannel socket

        initialModel =
            Model.initialModel location stateSocket eventsSocket
    in
        ( initialModel
        , Cmd.batch [ (Cmd.map PhoenixMsg stateCmd), (Cmd.map PhoenixMsg eventsCmd) ]
        )
