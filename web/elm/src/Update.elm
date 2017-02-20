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
        , clustersDecoder
        , clusterStatusDecoder
        , dockerEventDecoder
        )
import API exposing (getClusters)


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

        GetClusters ->
            model ! [ getClusters model.baseUrl ]

        GotClusters result ->
            case result of
                Ok clusters ->
                    ( { model | clusters = clusters }
                    , Navigation.newUrl (urlFor Clusters)
                    )

                Err err ->
                    let
                        _ =
                            Debug.log "err" err
                    in
                        model ! []

        ActivateCluster id ->
            model
                ! [ clusterStatusDecoder
                        |> Http.post (model.baseUrl ++ "/api/clusters/" ++ id ++ "/activate") Http.emptyBody
                        |> Http.send ActivatedCluster
                  ]

        ActivatedCluster result ->
            case result of
                Ok clusterStatus ->
                    ( { model | clusterStatus = Just clusterStatus }
                    , Navigation.newUrl (urlFor Clusters)
                    )

                Err err ->
                    let
                        _ =
                            Debug.log "err" err
                    in
                        model ! []
