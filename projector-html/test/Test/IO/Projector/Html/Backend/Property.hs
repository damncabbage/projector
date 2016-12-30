{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}
module Test.IO.Projector.Html.Backend.Property where


import qualified Data.List as L
import qualified Data.Text as T
import qualified Data.Text.IO as T

import           Disorder.Core.IO
import           Disorder.Jack

import           P

import           System.Directory (createDirectoryIfMissing)
import           System.Exit (ExitCode(..))
import           System.FilePath.Posix ((</>), (<.>), takeDirectory)
import           System.IO (FilePath, IO)
import           System.IO.Temp (withTempDirectory)


processProp :: ([Char] -> Property) -> (ExitCode, [Char], [Char]) -> Property
processProp f (code, out, err) =
  case code of
    ExitSuccess ->
      f out
    ExitFailure i ->
      let errm = L.unlines [
              "Process exited with failing status: " <> T.unpack (renderIntegral i)
            , err
            ]
      in counterexample errm (property False)


fileProp :: FilePath -> Text -> (FilePath -> IO a) -> (a -> Property) -> Property
fileProp mname modl f g =
  testIO . withTempDirectory "./dist/" "gen-hs-XXXXXX" $ \tmpDir -> do
    let path = tmpDir </> mname <.> "hs"
        dir = takeDirectory path
    createDirectoryIfMissing True dir
    T.writeFile path modl
    fmap g (f path)
