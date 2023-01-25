{-# LANGUAGE InstanceSigs #-}
{-# LANGUAGE TemplateHaskell #-}

module Beckn.External.Maps.Types
  ( module Beckn.External.Maps.Types,
    module Data.Geospatial,
    module Data.LineString,
  )
where

import Beckn.Storage.Esqueleto (derivePersistField)
import Beckn.Utils.GenericPretty (PrettyShow)
import Control.Lens.Operators
import Data.Geospatial
import Data.LineString
import Data.OpenApi
import Data.Text
import EulerHS.Prelude
import Servant.API (FromHttpApiData (..), ToHttpApiData (..))

data MapsService = Google | OSRM | MMI
  deriving (Show, Read, Eq, Ord, Generic, ToJSON, FromJSON, ToSchema)

derivePersistField "MapsService"

data LatLong = LatLong
  { lat :: Double,
    lon :: Double
  }
  deriving (Show, Eq, Generic, FromJSON, ToJSON, ToSchema, PrettyShow)

instance ToParamSchema LatLong where
  toParamSchema _ =
    mempty
      & title ?~ "LatLong"
      & type_ ?~ OpenApiString
      & format ?~ "<latitude>,<longitude>"

instance FromHttpApiData LatLong where
  parseUrlPiece a = do
    (lat, long) <- case splitOn "," a of
      [lat, long] -> Right (lat, long)
      _ -> Left "Unable to parse LatLong,"
    LatLong <$> readEither lat <*> readEither long

instance ToHttpApiData LatLong where
  toQueryParam :: LatLong -> Text
  toQueryParam LatLong {..} = show lat <> "," <> show lon
