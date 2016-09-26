{-# LANGUAGE OverloadedStrings #-}

import System.Exit
import Control.Monad
import Data.Maybe
import Text.Megaparsec
import VariationalCompiler.Entities
import VariationalCompiler.Json
import VariationalCompiler.View
import Data.Aeson
import Data.ByteString.Lazy.Char8(ByteString, putStrLn, getContents, pack)
import Prelude hiding (putStrLn, getContents)


-- | Decode input data from stdin, the parsed ast and
--   the selection, and use that info to generate a
--   call to getView. Encode the result of the view
--   in JSON and return it to stdout.
main :: IO ()
main = getContents >>= either putFailure putSuccess . eitherDecode

-- Print the message returned by aeson and then set the exit status
putFailure :: String -> IO ()
putFailure = putStrLn . pack >=> const exitFailure

-- Generate the view, then reencode and print it
putSuccess :: Projection -> IO ()
putSuccess = putStrLn . encode . viewProjection
