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
    { services : List Service
    , phxSocket : Phoenix.Socket.Socket Msg
    }


type alias Service =
    { name : String
    , replicas : Int
    , image : String
    , id : String
    }


type alias Payload =
    { services : List Service
    }


serviceDecoder : JD.Decoder Service
serviceDecoder =
    JD.succeed Service
        |: (JD.field "name" JD.string)
        |: (JD.field "replicas" JD.int)
        |: (JD.field "image" JD.string)
        |: (JD.field "id" JD.string)


serviceListDecoder : JD.Decoder (List Service)
serviceListDecoder =
    JD.list serviceDecoder


payloadDecoder : JD.Decoder Payload
payloadDecoder =
    JD.succeed Payload
        |: (JD.field "services" serviceListDecoder)


type Msg
    = PhoenixMsg (Phoenix.Socket.Msg Msg)
    | ReceiveServices JE.Value
    | ReceiveInitialState JE.Value


socketServer : String
socketServer =
    "ws://localhost:4000/socket/websocket"


initPhxSocket : Phoenix.Socket.Socket Msg
initPhxSocket =
    Phoenix.Socket.init socketServer
        |> Phoenix.Socket.withDebug
        |> Phoenix.Socket.on "services" "state:docker" ReceiveServices


joinChannel : String -> Phoenix.Socket.Socket Msg -> ( Phoenix.Socket.Socket Msg, Cmd (Phoenix.Socket.Msg Msg) )
joinChannel name socket =
    let
        payload =
            JE.object [ ( "init", JE.string "services" ) ]

        channel =
            Phoenix.Channel.init name
                |> Phoenix.Channel.withPayload payload
                |> Phoenix.Channel.onJoin ReceiveInitialState

        ( phxSocket, phxCmd ) =
            Phoenix.Socket.join channel socket
    in
        ( phxSocket, phxCmd )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ReceiveInitialState raw ->
            case JD.decodeValue serviceListDecoder raw of
                Ok services ->
                    ( { model | services = services }
                    , Cmd.none
                    )

                Err error ->
                    let
                        log =
                            Debug.log "error" error
                    in
                        ( model, Cmd.none )

        ReceiveServices raw ->
            case JD.decodeValue payloadDecoder raw of
                Ok payload ->
                    ( { model | services = payload.services }
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


viewService : Service -> Html Msg
viewService service =
    tr []
        [ td [] [ text service.name ]
        , td [] [ text (toString service.replicas) ]
        , td [] [ text service.image ]
        , td [] [ text service.id ]
        ]



-- ul
--     [ class "service" ]
--     [ li [] [ text (service.name) ]
--     ]


view : Model -> Html Msg
view model =
    div []
        [ node "vaadin-grid"
            []
            [ table []
                [ colgroup [] [ col [] [], col [] [], col [] [] ]
                , thead []
                    [ tr []
                        [ th [] [ text "Name" ]
                        , th [] [ text "Replicas" ]
                        , th [] [ text "Image" ]
                        , th [] [ text "ID" ]
                        ]
                    ]
                , tbody [] (List.map viewService model.services)
                ]
            ]
        ]


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    Phoenix.Socket.listen model.phxSocket PhoenixMsg


init : ( Model, Cmd Msg )
init =
    let
        socket =
            initPhxSocket

        ( phxSocket, phxCmd ) =
            joinChannel "state:docker" socket
    in
        ( { services = [], phxSocket = phxSocket }, Cmd.map PhoenixMsg phxCmd )
