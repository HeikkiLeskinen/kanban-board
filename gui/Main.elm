module Main exposing (..)

import Browser
import EventHelpers exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Models exposing (..)
import Views exposing (..)
import Time exposing (posixToMillis)

main : Program () Model Msg
main = Browser.element
        { init = initModel
        , subscriptions = subscriptions
        , update = update
        , view = view
        }

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        KeyDown key ->
            if key == 13 then
                addNewTask model

            else
                ( model, Cmd.none )

        TextInput content ->
            ( { model | taskInput = content }, Cmd.none )

        Move selectedTask ->
            ( { model | movingTask = Just selectedTask }, Cmd.none )

        DragOver _ ->
            ( model, Cmd.none )
        
        DropTask targetStatus ->
            moveTask model targetStatus

        DropTaskOnTask targetTask ->
            moveTaskOnTask model targetTask

        Delete content ->
            deleteTask model content

        Snooze content ->
            snoozeTask model content

        UpdateTasks tasks ->
            ( { model | tasks = tasks }, Cmd.none )
        
        SendRequest command ->
            ( model, sendRequest (encodeCommand command) )
        
        OnTime now ->
            ( { model | currentTimeEpoc = posixToMillis now // 1000 }, Cmd.none)


view : Model -> Html Msg
view model =
    let
        todos =
            getToDoTasks model

        inprogress =
            getInProgressTasks model

        dones =
            getDoneTasks model
    in
    div [ class "container dark" ]
        [ input
            [ type_ "text"
            , class "task-input"
            , placeholder "What's on your mind right now?"
            , tabindex 0
            , onKeyDown KeyDown
            , onInput TextInput
            , value model.taskInput
            ]
            []
        , div [ class "kanban-board" ]
            [ taskColumnView "Todo" todos
            , taskColumnView "InProgress" inprogress
            , taskColumnView "Done" dones
            ]
        ]
