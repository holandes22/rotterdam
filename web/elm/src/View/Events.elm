module View.Events exposing (view)

import Html exposing (Html, ul, li, div, text)
import Html.Attributes exposing (class)
import Msg exposing (Msg(..))
import Model exposing (Model)
import Types exposing (DockerEvent)


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
        ]
