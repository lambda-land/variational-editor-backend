module VariationalCompiler.Parser where

import VariationalCompiler.Entities
import Control.Applicative (empty)
import Control.Monad (void)
import Text.Megaparsec
import Text.Megaparsec.String
import qualified Text.Megaparsec.Lexer as L
import Data.Scientific as Scientific
import Data.Aeson
import Data.Text(pack)
import Data.Functor.Identity

-- Parser

-- | Consume white space.
sc :: Parser ()
sc = L.space (void spaceChar) empty empty

getLineCol :: ParsecT Dec String Identity LineCol
getLineCol = fromSourcePos <$> getPosition

-- | Parse the concrete choice syntax into Segment node in ast
doubleChoiceSegment :: Parser Segment
doubleChoiceSegment =
  do start <- getLineCol
     string "#ifdef" <?> "Choice keyword 2"
     spaceChar
     name <- many alphaNumChar
     r1 <- region
     r2 <- elseBranch
     string "#endif" <?> "End keyword 2"
     end <- getLineCol
     return (ChoiceSeg $ Choice name "positive" r1 r2 (Span start end))
  <?> "Choice node"

elseBranch :: Parser Region
elseBranch =
  try (
    do string "#else" <?> "Else keyword"
       region
  ) <|> (
    do start <- getLineCol
       return (Region [] (Span start start)))

doubleContraChoiceSegment :: Parser Segment
doubleContraChoiceSegment =
  do start <- getLineCol
     string "#ifndef" <?> "Choice keyword 2"
     spaceChar
     name <- many alphaNumChar
     r1 <- region
     r2 <- elseBranch
     string "#endif" <?> "End keyword 2"
     end <- getLineCol
     return (ChoiceSeg $ Choice name "contrapositive" r1 r2 (Span start end))
  <?> "Choice node"

-- | Parse input into string until a choice keyword is encountered
--   then return the string as a text segment.
textSegment :: Parser Segment
textSegment = do
  start <- getLineCol
  s <- someTill anyChar
    (lookAhead
      (choice
        [void (string "#ifdef" <?> "Choice lookahead")
        , void (string "#ifndef" <?> "Negative Choice lookahead")
        , void (string "#else" <?> "Else lookahead")
        , void (string "#endif" <?> "End lookahead")
        , eof]))
  end <- getLineCol
  return (ContentSeg $ Content s (Span start end))

-- | Parse either a choice or a text segment
segment :: Parser Segment
segment = choice [try doubleChoiceSegment <|> doubleContraChoiceSegment, textSegment]

-- | Parse a series of segments (a region or a program
region :: Parser Region
region = do
  start <- getLineCol
  segs <- manyTill segment
    (lookAhead
      (choice
        [void (string "#else" <?> "Else lookahead")
        , void (string "#endif" <?> "End lookahead")
        , eof]))
  end <- getLineCol
  return (Region segs (Span start end))

-- | Main parser for variational programs.
program :: Parser Region
program = region
