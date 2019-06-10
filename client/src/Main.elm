module Main exposing (main)

import Browser
import Html exposing (text)
import Http


main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


type alias Model =
    String


type Msg
    = GotString (Result Http.Error String)


init : () -> ( Model, Cmd Msg )
init _ =
    ( ""
    , Http.get
        { url = "http://localhost:9170"
        , expect = Http.expectString GotString
        }
    )


update message model =
    case message of
        GotString result ->
            case Debug.log "result" result of
                Ok string ->
                    ( string, Cmd.none )

                Err err ->
                    case err of
                        Http.BadUrl s ->
                            ( s, Cmd.none )

                        Http.Timeout ->
                            ( "Timeout", Cmd.none )

                        Http.NetworkError ->
                            ( "NetworkError", Cmd.none )

                        Http.BadStatus s ->
                            ( String.fromInt s, Cmd.none )

                        Http.BadBody b ->
                            ( b, Cmd.none )


subscriptions model =
    Sub.none


view model =
    text model
