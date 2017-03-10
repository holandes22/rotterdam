module View.Services.New exposing (view)

import Html exposing (..)
import Html.Events exposing (onInput, onClick)
import Html.Attributes exposing (attribute, value, class, name, placeholder, type_)
import Model exposing (Model)
import Msg exposing (Msg(..))
import Types exposing (FormField(..))
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Grid.Row as Row
import Bootstrap.Form as Form
import Bootstrap.Form.Checkbox as Checkbox
import Bootstrap.Form.Input as Input
import Bootstrap.Button as Button


view : Model -> Html Msg
view model =
    let
        service =
            Maybe.withDefault { name = "", image = "" } model.serviceForm
    in
        Form.form []
            [ Form.row []
                [ Form.colLabel [ Col.sm2 ] [ text "Name" ]
                , Form.col [ Col.sm10 ]
                    [ Input.text
                        [ Input.attrs
                            [ placeholder "Name"
                            , value service.name
                            , onInput <| UpdateServiceForm << Name
                            ]
                        ]
                    ]
                ]
            , Form.row []
                [ Form.colLabel [ Col.sm2 ] [ text "Image" ]
                , Form.col [ Col.sm10 ]
                    [ Input.text
                        [ Input.attrs
                            [ placeholder "Image"
                            , value service.image
                            , onInput <| UpdateServiceForm << Image
                            ]
                        ]
                    ]
                ]
              -- TODO: enable submit only if form is valid
            , Form.row [ Row.rightSm ]
                [ Form.col [ Col.sm2 ]
                    [ Button.button
                        [ Button.primary, Button.attrs [ class "float-right", onClick CreateService ] ]
                        [ text "Create" ]
                    ]
                ]
            ]
