module View.Clusters exposing (view)

import Model exposing (Model)
import Msg exposing (Msg(..))
import Html exposing (Html, div, text, button, ul, li)
import Html.Events exposing (onClick)
import Html.Attributes exposing (class)
import Types exposing (Cluster, Node)
import RemoteData exposing (..)


view : Model -> Html Msg
view model =
    case model.cluster of
        NotAsked ->
            text "should not happen"

        Loading ->
            text "Loading cluster..."

        Failure err ->
            text ("Error: " ++ toString err)

        Success cluster ->
            div []
                [ viewCluster cluster
                , viewClusterConnect cluster
                ]


viewCluster : Cluster -> Html Msg
viewCluster cluster =
    div []
        [ text ("Cluster status")
        , ul [] (List.map viewNode cluster.nodes)
        ]


viewNode : Node -> Html Msg
viewNode node =
    li [] [ text (node.label ++ " : " ++ node.status) ]


viewClusterConnect : Cluster -> Html Msg
viewClusterConnect cluster =
    if not cluster.connected then
        div [ class "ui button", onClick ActivateCluster ] [ text "Connect" ]
    else
        div [] []
