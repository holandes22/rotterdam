module View.Clusters exposing (view)

import Model exposing (Model)
import Msg exposing (Msg(..))
import Html exposing (Html, div, text, button, ul, li)
import Html.Events exposing (onClick)
import Html.Attributes exposing (class)
import Types exposing (Cluster, Node)


view : Model -> Html Msg
view model =
    div []
        [ viewNodes model.cluster
        , viewClusterConnect model.cluster
        ]


viewNodes : Cluster -> Html Msg
viewNodes cluster =
    div []
        [ text ("Cluster " ++ cluster.label ++ " status")
        , ul [] (List.map viewNode cluster.nodes)
        ]


viewNode : Node -> Html Msg
viewNode node =
    li [] [ text (node.label ++ " : " ++ node.status) ]


viewClusterConnect : Cluster -> Html Msg
viewClusterConnect cluster =
    let
        child =
            if not cluster.connected then
                div [ class "ui button", onClick ActivateCluster ] [ text "Connect" ]
            else
                div [] []
    in
        div []
            [ text cluster.label
            , child
            ]
