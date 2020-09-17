module Views exposing (..)

import EventHelpers exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Models exposing (..)

empty : Html msg
empty =
    Html.text ""


when : Bool -> Html msg -> Html msg
when shouldRender view =
    if shouldRender then
        view

    else
        empty

-- CARD VIEW

taskItemView : Int -> Task -> Html Msg
taskItemView index task =
    li
        [ class <| "task-item " ++ String.toLower task.status
        , attribute "draggable" "true"
        , onDragStart <| Move task
        , onDragOver <| DragOver task.subject
        , onDrop <| DropTaskOnTask task
        , attribute "ondragstart" "event.dataTransfer.setData('text/plain', '')"
        ]
        [ enrichItemContent task.subject
        , button
            [ class "btn-delete"
            , onClick <| Delete task.subject
            ]
            [ text "+" ]
        , button
            [ class "btn-snooze"
            , onClick <| Snooze task.subject
            ]
            [ text "z" ] 
            |> when (task.status == "InProgress")
        ]


enrichItemContent : String -> Html Msg
enrichItemContent str =
    List.map
        (\word ->
            if String.startsWith "http" word then
                a [ target "_blank", href word ] [ text word ]

            else
                text word
        )
        (String.words str)
        |> List.intersperse (text " ")
        |> Html.div []



-- COLUMN VIEW


taskColumnView : String -> List Task -> Html Msg
taskColumnView status list =
    div
        [ class <| "category " ++ String.toLower status
        , onDragOver <| DragOver status
        , onDrop <| DropTask status
        ]
        [ h2 [] [ text status ]
        , span [] [ text (String.fromInt (List.length list) ++ " item(s)") ]
        , ul [] (List.indexedMap taskItemView list)
        ]
