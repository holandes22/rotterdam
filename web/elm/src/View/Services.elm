module View.Services exposing (view)

import Html exposing (..)
import Html.Attributes exposing (value, placeholder, class, attribute)
import Html.Events exposing (onClick)
import Msg exposing (Msg(..))
import Types exposing (Service)
import Model exposing (Model)
import Routing exposing (Route(..))
import Bootstrap.Grid as Grid
import Bootstrap.Button as Button


view : Model -> Html Msg
view model =
    div []
        [ Button.button
            [ Button.outlinePrimary, Button.attrs [ onClick (NavigateTo (Just NewService)) ] ]
            [ text "create" ]
        , legend [] []
        , table [ class "table" ]
            [ thead []
                [ tr []
                    [ th [] [ text "Name" ]
                    , th [] [ text "Replicas" ]
                    , th [] [ text "Image" ]
                    , th [] [ text "ID" ]
                    ]
                ]
            , tbody [] (List.map viewServiceRow model.services)
            ]
        ]


viewServiceRow : Service -> Html Msg
viewServiceRow service =
    tr []
        [ td []
            [ a [ onClick (GetService service.id) ] [ text service.name ]
            ]
        , td [] [ text (toString service.replicas) ]
        , td [] [ text service.image ]
        , td [] [ text service.id ]
        ]
