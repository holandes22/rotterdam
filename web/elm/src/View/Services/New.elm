module View.Services.New exposing (view)

import Html exposing (Html, div, text)
import Model exposing (Model)
import Msg exposing (Msg(..))


view : Model -> Html Msg
view model =
    div [] [ text "Create a new service" ]
