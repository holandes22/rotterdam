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
import Bootstrap.Table as Table


view : Model -> Html Msg
view model =
    div []
        [ Button.button
            [ Button.outlinePrimary, Button.attrs [ onClick (NavigateTo (Just NewService)) ] ]
            [ text "create" ]
        , legend [] []
        , Table.simpleTable
            ( Table.simpleThead
                [ Table.th [] [ text "Name" ]
                , Table.th [] [ text "Replicas" ]
                , Table.th [] [ text "Image" ]
                , Table.th [] [ text "ID" ]
                ]
            , Table.tbody [] (List.map viewServiceRow model.services)
            )
        ]


viewServiceRow : Service -> Table.Row Msg
viewServiceRow service =
    Table.tr []
        [ Table.td []
            [ a [ onClick (GetService service.id) ] [ text service.name ]
            ]
        , Table.td [] [ text (toString service.replicas) ]
        , Table.td [] [ text service.image ]
        , Table.td [] [ text service.id ]
        ]
