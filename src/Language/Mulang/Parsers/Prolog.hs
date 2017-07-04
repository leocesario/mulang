{-# LANGUAGE RankNTypes #-}

module Language.Mulang.Parsers.Prolog  (pl, parseProlog) where

import Text.Parsec
import Text.Parsec.Numbers

import Language.Mulang.Ast
import Language.Mulang.Builder
import Language.Mulang.Parsers

import Data.Maybe (maybeToList)
import Data.Char (isUpper)

import Control.Fallible

type ParsecParser a = forall x . Parsec String x a

pl :: Parser
pl = orFail . parseProlog'

parseProlog :: MaybeParser
parseProlog = orNothing . parseProlog'

parseProlog' = fmap compact . parse program ""

program :: ParsecParser [Expression]
program = many predicate

pattern :: ParsecParser Pattern
pattern = choice [try number, try wildcard, other] <* spaces
  where
    wildcard :: ParsecParser Pattern
    wildcard = string "_" >> return WildcardPattern

    number :: ParsecParser Pattern
    number = fmap (LiteralPattern . show) parseFloat

    other :: ParsecParser Pattern
    other = fmap otherToPattern phead

    otherToPattern (name, []) | isUpper . head $ name = VariablePattern name
                              | otherwise = LiteralPattern name
    otherToPattern (name, args) = FunctorPattern name args

fact :: ParsecParser Expression
fact = do
  (name, args) <- phead
  end
  return $ Fact name args

rule :: ParsecParser Expression
rule = do
  (name, args) <- phead
  def
  consults <- body
  end
  return $ Rule name args consults

phead :: ParsecParser (Identifier, [Pattern])
phead = do
  name <- identifier
  args <- patternsList
  spaces
  return (name, concat.maybeToList $ args)

forall :: ParsecParser Expression
forall = do
  string "forall"
  startTuple
  c1 <- consult
  separator
  c2 <- consult
  endTuple
  return $ Forall c1 c2

findall :: ParsecParser Expression
findall = do
  string "findall"
  startTuple
  c1 <- consult
  separator
  c2 <- consult
  separator
  c3 <- consult
  endTuple
  return $ Findall c1 c2 c3

pnot :: ParsecParser Expression
pnot = do
  string "not"
  startTuple
  c <- consult
  endTuple
  return $ Not c

exist :: ParsecParser Expression
exist = fmap (\(name, args) -> Exist name args) phead

body :: ParsecParser [Expression]
body =  sepBy1 consult separator

inlineBody :: ParsecParser Expression
inlineBody = do
  startTuple
  queries <- body
  endTuple
  return $ Sequence queries

pinfix :: ParsecParser Expression
pinfix = do
  p1 <- pattern
  spaces
  operator <- choice . map try . map string $ ["is", ">=", "=<", "\\=", ">", "<", "="]
  spaces
  p2 <- pattern
  return $ Exist operator [p1, p2]

consult :: ParsecParser Expression
consult = choice [try findall, try forall, try pnot, try pinfix, inlineBody, exist]

predicate :: ParsecParser Expression
predicate = try fact <|> rule

patternsList :: ParsecParser (Maybe [Pattern])
patternsList = optionMaybe $ do
  startTuple
  args <- sepBy1 pattern separator
  endTuple
  return args


identifier = many letter
def = string ":-" >> spaces
startTuple = lparen >> spaces
endTuple = rparen >> spaces
separator = comma >> spaces
end = dot >> spaces

dot = char '.'
lparen = char '('
rparen = char ')'
comma = char ','
