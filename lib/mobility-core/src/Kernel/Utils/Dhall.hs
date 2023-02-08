{-# LANGUAGE CPP #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE UndecidableInstances #-}
{-# OPTIONS_GHC -Wno-orphans #-}

module Kernel.Utils.Dhall
  ( module Dhall,
    readDhallConfig,
    readDhallConfigDefault,
    customDecoder,
  )
where

import Data.Char (toUpper)
import Dhall hiding (map)
import EulerHS.Prelude
import qualified EulerHS.Types as T
import Servant.Client (BaseUrl, Scheme, parseBaseUrl)
import Servant.Client.Core (InvalidBaseUrlException (..))
import System.Environment (lookupEnv)

-- | Reads config which lies under the given path.
readDhallConfig :: FromDhall b => FilePath -> IO b
readDhallConfig = inputFile auto

-- | Reads config with a given type env. Gets application name as the second argument.
-- E.g. if @appname@ is "mock-provider-backend" the function first looks into "MOCK_PROVIDER_BACKEND_CONFIG_PATH"
-- env variable, if it's not set, it tries to read config from "./config/mock-provider-backend.dhall"
readDhallConfigDefault :: FromDhall b => String -> IO b
readDhallConfigDefault appname = do
  fname <- fromMaybe defCfgPath <$> lookupEnv envVarName
  readDhallConfig fname
  where
    defCfgPath = "./dhall-configs/dev/" ++ appname ++ ".dhall"
    envVarName = map norm appname ++ "_CONFIG_PATH"
    norm '-' = '_'
    norm c = toUpper c

-----------------------------------------------------

instance {-# OVERLAPS #-} Num a => FromDhall a where
  autoWith inn = fmap fromInteger (autoWith inn :: Decoder Integer)

instance FromDhall Word16 where
  autoWith inn = fmap fromIntegral (autoWith inn :: Decoder Natural)

deriving instance FromDhall Scheme

deriving instance FromDhall T.PoolConfig

deriving instance FromDhall T.PostgresConfig

deriving instance FromDhall T.RedisConfig

instance FromDhall BaseUrl where
  autoWith = customDecoder showBaseUrlErr parseBaseUrl . autoWith
    where
      showBaseUrlErr :: SomeException -> Text
      showBaseUrlErr e = case fromException e of
        Just (InvalidBaseUrlException msg) -> toText msg
        Nothing -> "Some unknown error: " <> show e

customDecoder :: (a1 -> Text) -> (t -> Either a1 a2) -> Decoder t -> Decoder a2
customDecoder ifErr parser Decoder {..} =
  Decoder
    { extract = \x -> fromMonadic do
        txt <- toMonadic (extract x)
        parser txt
          & either (toMonadic . extractError . ifErr) pure,
      ..
    }
