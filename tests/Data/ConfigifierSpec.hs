{-# LANGUAGE DataKinds                                #-}
{-# LANGUAGE OverlappingInstances                     #-}
{-# LANGUAGE OverloadedStrings                        #-}
{-# LANGUAGE TypeOperators                            #-}

{-# OPTIONS  #-}

module Data.ConfigifierSpec
where

import Control.Applicative
import Data.Proxy
import Data.String.Conversions
import Debug.Trace
import Prelude
import Test.Hspec
import Test.QuickCheck
import Text.Show.Pretty

import qualified Data.Aeson as Aeson
import qualified Data.Aeson.Encode.Pretty as Aeson

import Data.Configifier

import Test.Arbitrary ()


tests :: IO ()
tests = hspec spec

spec :: Spec
spec = describe "Configifier" $ do
    misc

misc :: Spec
misc = describe "misc" $ do
    describe "<<>>" $ do
        it "does not crash" . property $ \ a b -> (length . show $ a <<>> b) > 0

{-
    describe "(>.)" $ do
        it "works (unit)" $ do
            (cfg >. (Proxy :: Proxy "bla") :: Int) `shouldBe` 3
            ((cfg >. (Proxy :: Proxy "blu") :: SubCfg) >. (Proxy :: Proxy "lii") :: Bool) `shouldBe` False
            ((>. (Proxy :: Proxy "go")) <$> (cfg >. (Proxy :: Proxy "uGH") :: [Cfg']) :: [ST]) `shouldBe` ["drei","vier"]
-}

    describe "FromJSON, ToJSON" $ do
        it "is mutually inverse" $ do
            simpleJSONTest False cfg
            simpleJSONTest False subCfg
            sequence_ (simpleJSONTest False <$> cfg's)

    describe "parseShellEnv" $ do
        it "works" $ do
            parseShellEnv (Proxy :: Proxy ("bla" :> Int)) [("BLA", "3")] `shouldBe`
                (Right $ Aeson.object ["bla" Aeson..= Aeson.Number 3.0])

simpleJSONTest :: (Eq a, Aeson.FromJSON a, Aeson.ToJSON a, Show a) => Bool -> a -> IO ()
simpleJSONTest noisy x = _trace $ x' `shouldBe` Aeson.Success x
  where
    x' = Aeson.fromJSON $ Aeson.toJSON x
    _trace = if noisy
        then trace $ cs (Aeson.encodePretty x) ++ "\n" ++ ppShow (x, x')
        else id

type Cfg =
     "bla" :>: "description of bla" :> Int
  :| "blu" :> SubCfg
  :| "uGH" :>: "...  and something about uGH" :> [Cfg']

type Cfg' =
     "go"  :> ST
  :| "blu" :> SubCfg

type SubCfg =
     "lii" :> Bool

cfg :: Cfg
cfg =
     Proxy :>: Proxy :> 3
  :| Proxy :> subCfg
  :| Proxy :>: Proxy :> cfg's

cfg's :: [Cfg']
cfg's =
    [ Proxy :> "drei" :| Proxy :> Proxy :> True
    , Proxy :> "vier" :| Proxy :> Proxy :> False
    ]

subCfg :: SubCfg
subCfg = Proxy :> False
