module Encoders exposing (..)

import Types exposing (ServiceForm)
import Json.Encode exposing (Value, string, object)


encodeServiceForm : ServiceForm -> Value
encodeServiceForm service =
    object
        [ ( "name", string service.name )
        , ( "image", string service.image )
        ]
