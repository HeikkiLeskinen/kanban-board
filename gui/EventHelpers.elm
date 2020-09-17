module EventHelpers exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode


onKeyDown : (Int -> msg) -> Attribute msg
onKeyDown tagger =
    on "keydown" (Decode.map tagger keyCode)

onDragStart : msg -> Attribute msg
onDragStart message =
    on "dragstart" (Decode.succeed message)

onDragOver : msg -> Attribute msg
onDragOver message =
    hijackOn "dragover" (Decode.succeed message)

onDrop : msg -> Attribute msg
onDrop message = 
    hijackOn "drop" (Decode.succeed message)

hijackOn : String -> Decode.Decoder msg -> Attribute msg
hijackOn event decoder =
  preventDefaultOn event (Decode.map hijack decoder)

hijack : msg -> (msg, Bool)
hijack msg =
  (msg, True)
