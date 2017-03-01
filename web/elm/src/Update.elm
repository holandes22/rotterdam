module Update exposing (update)

import Http
import RemoteData
import Navigation
import Phoenix.Socket
import UrlParser as Url
import Routing exposing (..)
import Model exposing (Model)
import Msg exposing (Msg(..))
import Types exposing (Service, FormField(..))
import Json.Decode exposing (decodeValue, field)
import Decoders
    exposing
        ( serviceDecoder
        , servicesDecoder
        , clusterDecoder
        , dockerEventDecoder
        )
import API


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

        CreateService ->
            let
                cmd =
                    case model.serviceForm of
                        Nothing ->
                            Cmd.none

                        Just form ->
                            API.createService model.baseUrl form
            in
                ( { model | serviceForm = Nothing }
                , cmd
                )

        ServiceCreated result ->
            case result of
                Ok id ->
                    model ! [ Navigation.newUrl (urlFor Services) ]

                Err err ->
                    let
                        _ =
                            Debug.log "err" err
                    in
                        model ! []

        GetCluster ->
            ( { model | cluster = RemoteData.Loading }
            , API.getCluster model.baseUrl
            )

        GotCluster cluster ->
            ( { model | cluster = cluster }
            , Cmd.none
            )

        ActivateCluster ->
            ( { model | cluster = RemoteData.Loading }
            , API.connectCluster model.baseUrl
            )

        UpdateServiceForm field ->
            let
                form =
                    Maybe.withDefault { name = "", image = "" } model.serviceForm

                serviceForm =
                    case field of
                        Name name ->
                            { form | name = name }

                        Image image ->
                            { form | image = image }
            in
                ( { model | serviceForm = Just serviceForm }
                , Cmd.none
                )
