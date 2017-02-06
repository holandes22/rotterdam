module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (value, placeholder, class, attribute)
import Html.Events exposing (onInput, onClick)
import Phoenix.Socket
import Phoenix.Channel
import Phoenix.Push
import Json.Encode as JE
import Json.Decode as JD
import Json.Decode.Extra exposing ((|:))


type alias Model =
    { events : List DockerEvent
    , phxSocket : Phoenix.Socket.Socket Msg
    }


type alias DockerEvent =
    { nodeLabel : String
    , container : String
    , eventType : String
    , action : String
    , serviceName : String
    , serviceId : String
    , image : String
    , time : Int
    }


dockerEventDecoder : JD.Decoder DockerEvent
dockerEventDecoder =
    JD.succeed DockerEvent
        |: (JD.field "node_label" JD.string)
        |: (JD.field "container" JD.string)
        |: (JD.field "type" JD.string)
        |: (JD.field "action" JD.string)
        |: (JD.field "service_name" JD.string)
        |: (JD.field "service_id" JD.string)
        |: (JD.field "image" JD.string)
        |: (JD.field "time" JD.int)


type Msg
    = PhoenixMsg (Phoenix.Socket.Msg Msg)
    | ReceiveEvent JE.Value


initialModel : Model
initialModel =
    { events = []
    , phxSocket = initPhxSocket
    }


socketServer : String
socketServer =
    "ws://localhost:4000/socket/websocket"


initPhxSocket : Phoenix.Socket.Socket Msg
initPhxSocket =
    Phoenix.Socket.init socketServer
        |> Phoenix.Socket.withDebug
        |> Phoenix.Socket.on "event" "events:docker" ReceiveEvent


joinChannel : String -> Phoenix.Socket.Socket Msg -> ( Phoenix.Socket.Socket Msg, Cmd (Phoenix.Socket.Msg Msg) )
joinChannel name socket =
    let
        channel =
            Phoenix.Channel.init name

        ( phxSocket, phxCmd ) =
            Phoenix.Socket.join channel socket
    in
        ( phxSocket, phxCmd )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ReceiveEvent raw ->
            case JD.decodeValue dockerEventDecoder raw of
                Ok dockerEvent ->
                    ( { model | events = dockerEvent :: model.events }
                    , Cmd.none
                    )

                Err error ->
                    let
                        log =
                            Debug.log "error" error
                    in
                        ( model, Cmd.none )

        PhoenixMsg msg ->
            let
                ( phxSocket, phxCmd ) =
                    Phoenix.Socket.update msg model.phxSocket
            in
                ( { model | phxSocket = phxSocket }
                , Cmd.map PhoenixMsg phxCmd
                )


viewEvent : DockerEvent -> Html Msg
viewEvent event =
    ul
        [ class "event" ]
        [ li [] [ text (event.nodeLabel) ]
        , li [] [ text (event.eventType ++ "::" ++ event.action) ]
        , li [] [ text (toString event.time) ]
        ]


view : Model -> Html Msg
view model =
    div []
        [ div []
            (List.map viewEvent model.events)
          -- , div
          --     []
          --     [ text "Hellow"
          --     , node "paper-input"
          --         [ attribute "label" "Username" ]
          --         []
          --       -- add this
          --     , div
          --         []
          --         [ node "paper-button"
          --             []
          --             [ text "Clicky" ]
          --         ]
          --     ]
        ]


type alias Flags =
    { user : Int
    }


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    Phoenix.Socket.listen model.phxSocket PhoenixMsg


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        socket =
            initPhxSocket

        ( phxSocket, phxCmd ) =
            joinChannel "events:docker" socket

        a =
            Debug.log "flags" flags
    in
        ( { events = [], phxSocket = phxSocket }, Cmd.map PhoenixMsg phxCmd )
