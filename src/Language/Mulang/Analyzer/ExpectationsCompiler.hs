module Language.Mulang.Analyzer.ExpectationsCompiler(
  compileExpectation) where

import Language.Mulang
import Language.Mulang.Analyzer.Analysis (Expectation(..))

import Data.Maybe (fromMaybe)
import Data.List.Split (splitOn)

compileExpectation :: Expectation -> Inspection
compileExpectation = fromMaybe (\_ -> True) . compileMaybe

compileMaybe :: Expectation -> Maybe Inspection
compileMaybe (Expectation b i) = do
  let inspectionParts = splitOn ":" i
  let negator = compileNegator inspectionParts
  baseInspection <- compileBaseInspection inspectionParts
  slicer         <- compileSlicer (splitOn ":" b)
  return . negator . slicer $ baseInspection

compileSlicer :: [String] -> Maybe (Inspection -> Inspection)
compileSlicer [""]                  = Just id
compileSlicer ["Intransitive",name] = justSlicerFor scopedList name
compileSlicer [name]                = justSlicerFor transitiveList name
compileSlicer _                     = Nothing

justSlicerFor f name = Just (flip f (splitOn "." name))

compileNegator :: [String] -> (Inspection -> Inspection)
compileNegator ("Not":_) = negative
compileNegator _         = id

compileBaseInspection :: [String] -> Maybe (Inspection)
compileBaseInspection ["HasArity",n]        = Just $ declaresComputationWithExactArity (read n) anyone
compileBaseInspection ("Not":parts)         = compileBaseInspection parts
compileBaseInspection [verb]                = compileBaseInspection [verb, "*"]
compileBaseInspection [verb, object]        = compileInspectionPrimitive verb (compileObject object)
compileBaseInspection _                     = Nothing

compileObject :: String -> BindingPredicate
compileObject "*"        = anyone
compileObject ('~':name) = like name
compileObject ('=':name) = named name
compileObject name       = named name


compileInspectionPrimitive :: String -> BindingPredicate -> Maybe Inspection
compileInspectionPrimitive = f
  where

  f "HasRule"                        b = Just $ declaresRule b
  f "HasFact"                        b = Just $ declaresFact b
  f "HasPredicate"                   b = Just $ declaresPredicate b
  f "HasClass"                       b = Just $ declaresClass b
  f "HasObject"                      b = Just $ declaresObject b
  f "HasAttribute"                   b = Just $ declaresAttribute b
  f "HasMethod"                      b = Just $ declaresMethod b
  f "HasFunction"                    b = Just $ declaresFunction b
  f "HasProcedure"                   b = Just $ declaresProcedure b
  f "HasVariable"                    b = Just $ declaresVariable b
  f "HasTypeAlias"                   b = Just $ declaresTypeAlias b
  f "HasTypeSignature"               b = Just $ declaresTypeSignature b
  f "HasComputation"                 b = Just $ declaresComputation b
  f "HasUsage"                       b = Just $ uses b
  f "HasBinding"                     b = Just $ declares b
  f "HasArity0"                      b = Just $ declaresComputationWithExactArity 0 b
  f "HasArity1"                      b = Just $ declaresComputationWithExactArity 1 b
  f "HasArity2"                      b = Just $ declaresComputationWithExactArity 2 b
  f "HasArity3"                      b = Just $ declaresComputationWithExactArity 3 b
  f "HasDirectRecursion"             b = Just $ declaresRecursively b
  f "HasEntryPoint"                  _ = Just declaresEntryPoint
  f "HasAnonymousVariable"           _ = Just usesAnonymousVariable
  f "HasComposition"                 _ = Just usesComposition
  f "HasComprehension"               _ = Just usesComprehension
  f "HasConditional"                 _ = Just usesConditional
  f "HasUnifyOperator"               _ = Just usesUnifyOperator
  f "HasFindall"                     _ = Just usesFindall
  f "HasForall"                      _ = Just usesForall
  f "HasGuards"                      _ = Just usesGuards
  f "HasIf"                          _ = Just usesIf
  f "HasLambda"                      _ = Just usesLambda
  f "HasNot"                         _ = Just usesNot
  f "HasRepeat"                      _ = Just usesRepeat
  f "HasWhile"                       _ = Just usesWhile
  f "HasPatternMatching"             _ = Just usesPatternMatching
  f "HasSwitch"                      _ = Just usesSwitch
  f _                                _ = Nothing

