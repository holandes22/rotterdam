module View.Clusters exposing (view)

import Model exposing (Model)
import Msg exposing (Msg(..))
import Html.Events exposing (onClick)
import Html exposing (Html, div, text, button, ul, li)
import Types exposing (Cluster, NodeStatus)


view : Model -> Html Msg
view model =
    div []
        [ viewClusterStatus model
        , div []
            (List.map viewCluster model.clusters)
        ]


viewClusterStatus : Model -> Html Msg
viewClusterStatus model =
    case model.clusterStatus of
        Just status ->
            div []
                [ text ("Cluster " ++ status.label ++ " status")
                , ul [] (List.map viewNodeStatus status.nodes)
                ]

        Nothing ->
            div [] [ text "No active cluster" ]


viewNodeStatus : NodeStatus -> Html Msg
viewNodeStatus status =
    li [] [ text (status.label ++ " : " ++ status.status) ]


viewCluster : Cluster -> Html Msg
viewCluster cluster =
    let
        btn =
            if cluster.active then
                button [] [ text "Deactivate" ]
            else
                button
                    [ onClick (ActivateCluster cluster.id) ]
                    [ text "Activate" ]
    in
        div []
            [ text cluster.label
            , btn
            ]
