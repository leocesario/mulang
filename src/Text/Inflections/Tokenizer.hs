module Text.Inflections.Tokenizer (
  CaseStyle,
  camelCase,
  snakeCase,
  canTokenize,
  tokenize) where

import Data.Char (toLower)
import Data.Either (isRight)

import Text.Inflections
import Text.Inflections.Parse.Types
import Text.Parsec.Error (ParseError)

import Text.SimpleParser
import Control.Fallible

type CaseStyle = String -> Either Text.Parsec.Error.ParseError [Text.Inflections.Parse.Types.Word]

camelCase      :: CaseStyle
camelCase      = parseCamelCase []

snakeCase      :: CaseStyle
snakeCase      = parseSnakeCase []

canTokenize :: CaseStyle -> String -> Bool
canTokenize style = isRight . style

tokenize :: CaseStyle -> String -> [String]
tokenize style s | Just words <- (wordsOrNothing . style) s = concatMap toToken words
                 | otherwise = []
                  where toToken = return . map toLower


wordsOrNothing = fmap (concatMap c) . orNothing
                where c (Word w) = [w]
                      c _        = []
