module View.Services.Show exposing (view)

import Html exposing (Html, div, text)
import Model exposing (Model)
import Msg exposing (Msg(..))


view : Model -> Html Msg
view model =
    let
        name =
            case model.shownService of
                Just service ->
                    service.name

                Nothing ->
                    "N/A"
    in
        div [] [ text name ]
