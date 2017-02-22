module Update exposing (update)

import Http
import Navigation
import Phoenix.Socket
import UrlParser as Url
import Routing exposing (..)
import Model exposing (Model)
import Msg exposing (Msg(..))
import Types exposing (Service)
import Json.Decode exposing (decodeValue, field)
import Decoders
    exposing
        ( serviceDecoder
        , servicesDecoder
        , clusterDecoder
        , dockerEventDecoder
        )
import API exposing (getCluster)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NavigateTo location_ ->
            case location_ of
                Nothing ->
                    model ! []

                Just location ->
                    model ! [ Navigation.newUrl (Routing.urlFor location) ]

        UrlChange location ->
            let
                route =
                    routeFromLocation location
            in
                ( { model | route = route }
                , Cmd.none
                )

        OpenSideMenu ->
            ( { model | sideMenuActive = True }
            , Cmd.none
            )

        CloseSideMenu ->
            ( { model | sideMenuActive = False }
            , Cmd.none
            )

        PhoenixMsg msg ->
            let
                ( stateSocket, stateCmd ) =
                    Phoenix.Socket.update msg model.stateSocket

                ( eventsSocket, eventsCmd ) =
                    Phoenix.Socket.update msg model.eventsSocket
            in
                ( { model | stateSocket = stateSocket, eventsSocket = eventsSocket }
                , Cmd.batch [ (Cmd.map PhoenixMsg stateCmd), (Cmd.map PhoenixMsg eventsCmd) ]
                )

        ReceiveServicesInitialState raw ->
            case decodeValue servicesDecoder raw of
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
            case decodeValue (field "services" servicesDecoder) raw of
                Ok services ->
                    ( { model | services = services }
                    , Cmd.none
                    )

                Err error ->
                    let
                        log =
                            Debug.log "error" error
                    in
                        model ! []

        ReceiveDockerEvent raw ->
            case decodeValue dockerEventDecoder raw of
                Ok dockerEvent ->
                    ( { model | events = dockerEvent :: model.events }
                    , Cmd.none
                    )

                Err error ->
                    let
                        log =
                            Debug.log "error" error
                    in
                        model ! []

        GetService id ->
            model
                ! [ serviceDecoder
                        |> Http.get (model.baseUrl ++ "/api/services/" ++ id)
                        |> Http.send GotService
                  ]

        GotService result ->
            case result of
                Ok service ->
                    ( { model | shownService = Just service }
                    , Navigation.newUrl (urlFor (ShowService service.id))
                    )

                Err err ->
                    let
                        _ =
                            Debug.log "err" err
                    in
                        model ! []

        GetCluster ->
            model ! [ getCluster model.baseUrl ]

        GotCluster result ->
            case result of
                Ok cluster ->
                    ( { model | cluster = cluster }
                    , Navigation.newUrl (urlFor Clusters)
                    )

                Err err ->
                    let
                        _ =
                            Debug.log "err" err
                    in
                        model ! []

        ActivateCluster ->
            model
                ! [ clusterDecoder
                        |> Http.post (model.baseUrl ++ "/api/cluster/connect") Http.emptyBody
                        |> Http.send GotCluster
                  ]
