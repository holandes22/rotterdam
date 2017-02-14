module View.Home exposing (view)

import Model exposing (Model)
import Msg exposing (Msg(..))
import Html exposing (Html, text, div)


view : Model -> Html Msg
view model =
    div [] [ text "Welcome to nav test!" ]
