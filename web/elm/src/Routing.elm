module Routing exposing (Route(..), route, urlFor, routeFromLocation)

import Navigation
import UrlParser as Url exposing (s, top, parseHash, string, (</>))


type Route
    = Home
    | Services
    | NewService
    | ShowService String
    | Clusters


route : Url.Parser (Route -> a) a
route =
    Url.oneOf
        [ Url.map Home top
        , Url.map Services (s "services")
        , Url.map NewService (s "services" </> s "new")
        , Url.map ShowService (s "services" </> string)
        , Url.map Clusters (s "clusters")
          -- , Url.map BlogList (s "blog" <?> stringParam "search")
        ]


routeFromLocation : Navigation.Location -> Maybe Route
routeFromLocation location =
    Url.parseHash route location


urlFor : Route -> String
urlFor route =
    let
        url =
            case route of
                Home ->
                    "/"

                Services ->
                    "/services"

                NewService ->
                    "/services/new"

                ShowService id ->
                    "/services/" ++ id

                Clusters ->
                    "/clusters"
    in
        "#" ++ url
