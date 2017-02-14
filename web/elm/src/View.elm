module View exposing (view)

import Html exposing (Html, a, i, ul, li, div, text, main_)
import Html.Attributes exposing (class, href, id, attribute, classList)
import Html.Events exposing (onClick)
import Model exposing (Model)
import Msg exposing (Msg(..))
import Routing exposing (Route(..))
import View.Home
import View.Services
import View.Events
import View.Services.Show
import View.Clusters


view : Model -> Html Msg
view model =
    div []
        [ div [ id "layout", classList [ ( "active", model.sideMenuActive ) ] ]
            [ nav model
            , main_ [ attribute "role" "main" ] [ body model ]
            , View.Events.view model
            ]
        ]


nav : Model -> Html Msg
nav model =
    div [ id "nav-side-menu", classList [ ( "active", model.sideMenuActive ) ] ]
        [ a [ class "link", onClick OpenSideMenu ]
            [ i [ class "fa fa-bars" ]
                []
            ]
        , a [ class "close", onClick CloseSideMenu ]
            [ i [ class "fa fa-close" ]
                []
            ]
        , div []
            [ div [ class "menu-heading", onClick (NavigateTo (Just Home)) ]
                [ i [ class "fa fa-anchor" ] []
                , text "Rotterdam"
                ]
            , ul [ class "menu-list" ]
                [ li []
                    [ a
                        [ class "menu-link"
                        , classList [ ( "selected", selected model.route Services ) ]
                        , onClick (NavigateTo (Just Services))
                        ]
                        [ i [ class "fa fa-arrows" ] []
                        , text "Services"
                        ]
                    ]
                , li []
                    [ a
                        [ class "menu-link"
                        , classList [ ( "selected", selected model.route Clusters ) ]
                        , onClick GetClusters
                        ]
                        [ i [ class "fa fa-server" ] []
                        , text "Clusters"
                        ]
                    ]
                ]
            ]
        ]


selected : Maybe Routing.Route -> Routing.Route -> Bool
selected current expected =
    case current of
        Just route ->
            route == expected

        Nothing ->
            False


body : Model -> Html Msg
body model =
    case model.route of
        Just Home ->
            View.Home.view model

        Just Services ->
            View.Services.view model

        Just (Routing.ShowService id) ->
            View.Services.Show.view model

        Just Clusters ->
            View.Clusters.view model

        Nothing ->
            text "404 - Not found"