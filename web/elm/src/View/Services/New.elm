module View.Services.New exposing (view)

import Html exposing (..)
import Html.Events exposing (onInput)
import Html.Attributes exposing (attribute, value, class, name, placeholder, type_)
import Model exposing (Model)
import Msg exposing (Msg(..))
import Types exposing (FormField(..))


view : Model -> Html Msg
view model =
    let
        service =
            Maybe.withDefault { name = "", image = "" } model.serviceForm
    in
        form [ class "ui form" ]
            [ h4 [ class "ui dividing header" ]
                [ text "Create service" ]
            , div [ class "field" ]
                [ label []
                    [ text "Name" ]
                , div [ class "field" ]
                    [ input
                        [ name "name"
                        , placeholder "Name"
                        , value service.name
                        , type_ "text"
                        , onInput <| UpdateServiceForm << Name
                        ]
                        []
                    ]
                , label []
                    [ text "Image" ]
                , div [ class "field" ]
                    [ input
                        [ name "image"
                        , placeholder "Image"
                        , value service.image
                        , type_ "text"
                        , onInput <| UpdateServiceForm << Image
                        ]
                        []
                    ]
                ]
            , div [ class "ui button", attribute "tabindex" "0" ]
                [ text "Create" ]
            ]
