module Types exposing (..)


type alias Service =
    { name : String
    , replicas : Int
    , image : String
    , id : String
    }


type alias DockerEvent =
    { nodeLabel : String
    , container : String
    , eventType : String
    , action : String
    , serviceName : String
    , serviceId : String
    , image : String
    , time : Int
    }


type alias Cluster =
    { id : String
    , label : String
    , active : Bool
    , nodes : List Node
    }



-- TODO: Add cert_path, port and status_msg fields
-- and use the decoder in the flags passed to Main


type alias Node =
    { id : String
    , label : String
    , role : String
    , host : String
    , status : String
    }
