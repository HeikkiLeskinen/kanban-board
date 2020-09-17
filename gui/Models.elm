port module Models exposing (..)

import Dict exposing (..)
import Html.Attributes exposing (list)
import Html exposing (i)
import Time exposing (Posix, posixToMillis)
import Task exposing (perform)
import Ordering exposing (Ordering)
import Debug exposing (todo, log)

import Json.Encode.Extra exposing (maybe)
import Json.Encode as Encode exposing (Value, bool, encode, int, object, string)
import Json.Decode as Decode exposing (Decoder, field, map5)

type Msg
    = NoOp
    | KeyDown Int
    | TextInput String
    | Move Task
    | DragOver String
    | DropTask String  
    | DropTaskOnTask Task
    | Delete String
    | Snooze String
    | UpdateTasks (List Task)
    | SendRequest Command
    | OnTime Posix 

type alias Task =
    { subject : String
    , status : String 
    , priority : Float
    , waitUntil : Maybe Int
    , updated : Int
    }

type alias Model =
    { taskInput : String
    , tasks : List Task
    , movingTask : Maybe Task  
    , currentTimeEpoc : Int  
    }

type Command
    = Init
    | Log { text : String }
    | StoreTasks { tasks : List Task }

-- PORTS

port receiveResponse: (Value -> msg) -> Sub msg

port sendRequest: Value -> Cmd msg

tasksEncoder : Task -> Encode.Value
tasksEncoder task =  
    Encode.object
        [ 
          ( "subject", Encode.string task.subject )
        , ( "status", Encode.string task.status )
        , ( "priority", Encode.float task.priority )
        , ( "wait_until", maybe Encode.int task.waitUntil )
        , ( "updated", Encode.int task.updated )
        ]

taskListEncoder : (List Task) -> Encode.Value
taskListEncoder =
    Encode.list tasksEncoder

saveData : Model -> Cmd Msg
saveData model =
    sendRequest (encodeCommand (StoreTasks { tasks = model.tasks }))

encodeCommand : Command -> Value
encodeCommand command =
    case command of
        Init ->
            object [ ( "cmd", string "Init" ) ]

        Log { text } ->
            object [ ( "cmd", string "Log" ), ( "text", string text ) ]  
        
        StoreTasks { tasks } -> 
            object [ ( "cmd", string "StoreTasks" ), ( "tasks", taskListEncoder tasks ) ]  
        
-- INITIAL FUNCTION

initModel : () -> ( Model, Cmd Msg )
initModel _ =
    ( Model "" [] Nothing 0, sendRequest (encodeCommand Init) ) 

-- ADD TASK

addNewTask : Model -> ( Model, Cmd Msg )
addNewTask model =
    let
        newModel =
            { model
                | tasks = model.tasks ++ [ Task model.taskInput "Todo" 0 Nothing model.currentTimeEpoc ]
                , taskInput = ""
            }
    in
    ( newModel, Cmd.batch [ saveData newModel, Cmd.none ] )


-- CHANGE TASK PRIORITY

groupBy : (a -> comparable) -> List a -> Dict comparable (List a)
groupBy keyfn list =
    List.foldr
        (\x acc ->
            Dict.update (keyfn x) (Maybe.map ((::) x) >> Maybe.withDefault [ x ] >> Just) acc
        )
        Dict.empty
        list
        
resetPriorities : List Task -> List Task
resetPriorities tasks = 
    List.indexedMap Tuple.pair tasks
    |> Dict.fromList 
    >> Dict.map (\index t -> { t | priority = toFloat index})
    >> Dict.values

moveTaskOnTask : Model -> Task -> ( Model, Cmd Msg )
moveTaskOnTask model targetTask =
    let
        newTasks =
            case model.movingTask of
                Just task ->
                    model.tasks
                    |> groupBy .status
                    >> Dict.map 
                        (\_ -> List.map
                               (\t ->
                                if t.subject == task.subject then
                                    { t | priority = targetTask.priority - 0.5 }
                                else
                                    t
                                )
                            >> List.sortBy .priority       
                            >> resetPriorities
                        ) 
                    >> values
                    >> List.concat

                Nothing ->
                    model.tasks

        newModel =
            { model | tasks = newTasks, movingTask = Nothing }
    in
    ( newModel, Cmd.batch [ saveData newModel, Cmd.none ] )


-- CHANGE TASK STATUS

moveTaskToStatus : Task -> String -> Int -> List Task -> List Task
moveTaskToStatus taskToFind newTaskStatus timestamp tasks =
    List.map
        (\t ->
            if t.subject == taskToFind.subject then
                { t | status = newTaskStatus, updated = timestamp}
            else
                t
        )
        tasks


moveTask : Model -> String -> ( Model, Cmd Msg )
moveTask model targetStatus =
    let
        newTasks =
            case model.movingTask of
                Just task ->
                    moveTaskToStatus task targetStatus model.currentTimeEpoc model.tasks
                Nothing ->
                    model.tasks

        newModel =
            { model | tasks = newTasks, movingTask = Nothing }
    in
    ( newModel, Cmd.batch [ saveData newModel, Cmd.none ] )

-- DELETE TASK

deleteTask : Model -> String -> ( Model, Cmd Msg )
deleteTask model subject =
    let
        newModel =
            { model | tasks = List.filter (\x -> x.subject /= subject) model.tasks }
    in
    ( newModel, Cmd.batch [ saveData newModel, Cmd.none ] )


-- SNOOZE TASK

snoozeTask : Model -> String -> ( Model, Cmd Msg )
snoozeTask model subject =
    let
        newTasks = List.map
            (\t ->
                if t.subject == subject then
                    { t | status = "Snooze", waitUntil = Just (model.currentTimeEpoc + 3600) }
                else
                    t
            )
            model.tasks
        newModel =
            { model | tasks = newTasks }
    in
    ( newModel, Cmd.batch [ saveData newModel, Cmd.none ] )

-- GET TASKS BY STATUS

getInProgressTasks : Model -> List Task
getInProgressTasks model =
    List.sortBy .priority (List.filter (\t -> t.status == "InProgress") model.tasks)

statusOrdering : Ordering String
statusOrdering =
    Ordering.explicit ["Todo", "Snooze"]

toDoOrdering : Ordering Task
toDoOrdering = 
    Ordering.byFieldWith statusOrdering .status
        |> Ordering.breakTiesWith
                (Ordering.byField .priority)

getToDoTasks : Model -> List Task
getToDoTasks model =
    List.sortWith toDoOrdering (List.filter (\t -> t.status == "Todo" || t.status == "Snooze") model.tasks)


getDoneTasks : Model -> List Task
getDoneTasks model =
    List.sortBy .priority (List.filter (\t -> t.status == "Done") model.tasks)

-- SUBSCRIPTIONS

taskDecoder : Decoder Task
taskDecoder =
    map5 Task
        (field "subject" Decode.string)
        (field "status" Decode.string)
        (field "priority" Decode.float)
        (field "wait_until" (Decode.nullable Decode.int))
        (field "updated" Decode.int)

taskListDecoder : Decoder (List Task)
taskListDecoder =
    Decode.list taskDecoder

decodeContent : Decoder (List Task)
decodeContent =
  Decode.at [ "tasks" ] taskListDecoder

decodeValue : Value -> Msg
decodeValue x =
    let
        result = Decode.decodeValue decodeContent x

    in
    case result of
        Ok tasks ->
            UpdateTasks tasks

        Err err ->
            SendRequest (Log { text = Decode.errorToString err })             

subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch [ receiveResponse decodeValue, Time.every 1000 OnTime ]
    
