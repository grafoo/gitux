module Main exposing (main)

import Browser
import Char
import Dict
import Html exposing (Html, code, div, hr, span, strong, text)
import Http
import Json.Decode
import List


main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { gitStatus : Dict.Dict String FileStatus
    , error : Maybe String
    }


type Msg
    = GotJSON (Result Http.Error (Dict.Dict String FileStatus))


type StatusCode
    = Unmodified
    | Untracked
    | Modified
    | Added
    | Deleted
    | Renamed
    | Copied
    | UpdatedButUnmerged
    | Unknown


type alias FileStatus =
    { staging : StatusCode
    , worktree : StatusCode
    , extra : String
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { gitStatus =
            Dict.fromList
                [ ( ""
                  , { staging = Unknown
                    , worktree = Unknown
                    , extra = ""
                    }
                  )
                ]
      , error = Nothing
      }
    , Http.get
        { url = "http://localhost:9170"
        , expect = Http.expectJson GotJSON statusDecoder
        }
    )


statusDecoder =
    Json.Decode.dict
        (Json.Decode.map3 FileStatus
            (Json.Decode.field "Staging" Json.Decode.int |> Json.Decode.andThen decodeStatusCode)
            (Json.Decode.field "Worktree" Json.Decode.int |> Json.Decode.andThen decodeStatusCode)
            (Json.Decode.field "Extra" Json.Decode.string)
        )


decodeStatusCode statusCode =
    -- https://godoc.org/gopkg.in/src-d/go-git.v4#StatusCode
    case Char.fromCode statusCode of
        ' ' ->
            Json.Decode.succeed Unmodified

        '?' ->
            Json.Decode.succeed Untracked

        'M' ->
            Json.Decode.succeed Modified

        'A' ->
            Json.Decode.succeed Added

        'D' ->
            Json.Decode.succeed Deleted

        'R' ->
            Json.Decode.succeed Renamed

        'C' ->
            Json.Decode.succeed Copied

        'U' ->
            Json.Decode.succeed UpdatedButUnmerged

        _ ->
            Json.Decode.succeed Unknown


statusCodeToString statusCode =
    case statusCode of
        Unmodified ->
            "Unmodified"

        Untracked ->
            "Untracked"

        Modified ->
            "Modified"

        Added ->
            "Added"

        Deleted ->
            "Deleted"

        Renamed ->
            "Renamed"

        Copied ->
            "Copied"

        UpdatedButUnmerged ->
            "UpdatedButUnmerged"

        Unknown ->
            "Unknown"


filterStaged _ status =
    case status.staging of
        Modified ->
            True

        Added ->
            True

        Deleted ->
            True

        Renamed ->
            True

        Copied ->
            True

        _ ->
            False


filterUnstaged _ status =
    case status.worktree of
        Modified ->
            True

        Added ->
            True

        Deleted ->
            True

        Renamed ->
            True

        Copied ->
            True

        _ ->
            False


filterUntracked _ status =
    -- True
    let
        staging =
            (\s ->
                case s of
                    Untracked ->
                        True

                    _ ->
                        False
            )
                status.staging

        worktree =
            (\w ->
                case w of
                    Untracked ->
                        True

                    _ ->
                        False
            )
                status.worktree
    in
    staging && worktree


view : Model -> Html Msg
view model =
    div []
        [ -- staged
          strong [] [ text "Staged" ]
        , div []
            (Dict.values
                (Dict.map
                    (\filename status ->
                        span
                            []
                            [ text (statusCodeToString status.staging ++ ": ")
                            , code [] [ text filename ]
                            ]
                    )
                    (Dict.filter
                        filterStaged
                        model.gitStatus
                    )
                )
            )
        , hr [] []
        , strong [] [ text "Unstaged" ]
        , div []
            -- unstaged
            (Dict.values
                (Dict.map
                    (\filename status ->
                        span
                            []
                            [ text (statusCodeToString status.worktree ++ ": ")
                            , code [] [ text filename ]
                            ]
                    )
                    (Dict.filter
                        filterUnstaged
                        model.gitStatus
                    )
                )
            )
        , hr [] []
        , strong [] [ text "Untracked" ]
        , div []
            -- untracked
            (Dict.values
                (Dict.map
                    (\filename status -> div [] [ code [] [ text filename ] ])
                    (Dict.filter
                        filterUntracked
                        model.gitStatus
                    )
                )
            )
        ]


update message model =
    case message of
        GotJSON result ->
            case Debug.log "result" result of
                Ok status ->
                    ( { gitStatus = status, error = Nothing }, Cmd.none )

                Err error ->
                    ( { gitStatus =
                            Dict.fromList
                                [ ( ""
                                  , { staging = Unknown
                                    , worktree = Unknown
                                    , extra = ""
                                    }
                                  )
                                ]
                      , error = Just (httpErrorToString error)
                      }
                    , Cmd.none
                    )


httpErrorToString error =
    case error of
        Http.BadUrl s ->
            s

        Http.Timeout ->
            "Timeout"

        Http.NetworkError ->
            "NetworkError"

        Http.BadStatus s ->
            String.fromInt s

        Http.BadBody s ->
            s


subscriptions model =
    Sub.none
