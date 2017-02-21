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
        [ viewActiveCluster model
        , div []
            (List.map viewCluster model.clusters)
        ]


viewActiveCluster : Model -> Html Msg
viewActiveCluster model =
    case model.activeCluster of
        Just cluster ->
            div []
                [ text ("Cluster " ++ cluster.label ++ " status")
                , ul [] (List.map viewNode cluster.nodes)
                ]

        Nothing ->
            div [] [ text "No active cluster" ]


viewNode : Node -> Html Msg
viewNode node =
    li [] [ text (node.label ++ " : " ++ node.status) ]


viewCluster : Cluster -> Html Msg
viewCluster cluster =
    let
        btn =
            if cluster.active then
                div [ class "ui button" ] [ text "Deactivate" ]
            else
                div
                    [ class "ui button", onClick (ActivateCluster cluster.id) ]
                    [ text "Activate" ]
    in
        div []
            [ text cluster.label
            , btn
            ]
