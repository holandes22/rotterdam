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
    }


type alias NodeStatus =
    { label : String
    , status : String
    }


type alias ClusterStatus =
    { id : String
    , label : String
    , nodes : List NodeStatus
    }
