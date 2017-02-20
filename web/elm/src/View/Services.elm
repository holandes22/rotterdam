module View.Services exposing (view)

import Html exposing (..)
import Html.Attributes exposing (value, placeholder, class, attribute)
import Html.Events exposing (onClick)
import Msg exposing (Msg(..))
import Types exposing (Service)
import Model exposing (Model)
import Routing exposing (Route(..))


view : Model -> Html Msg
view model =
    table [ class "ui single line table" ]
        [ thead []
            [ tr []
                [ th [] [ text "Name" ]
                , th [] [ text "Replicas" ]
                , th [] [ text "Image" ]
                , th [] [ text "ID" ]
                , th [] [ text "Actions" ]
                ]
            ]
        , tbody [] (List.map viewServiceRow model.services)
        ]


viewServiceRow : Service -> Html Msg
viewServiceRow service =
    tr []
        [ td [] [ text service.name ]
        , td [] [ text (toString service.replicas) ]
        , td [] [ text service.image ]
        , td [] [ text service.id ]
        , td []
            [ div [ class "ui button", onClick (GetService service.id) ] [ text "Details" ] ]
        ]
