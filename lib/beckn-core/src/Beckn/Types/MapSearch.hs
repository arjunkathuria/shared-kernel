{-# LANGUAGE DuplicateRecordFields #-}
{-# OPTIONS_GHC -Wno-orphans #-}

module Beckn.Types.MapSearch
  ( module Beckn.Types.MapSearch,
    module Data.Geospatial,
    module Data.LineString,
  )
where

import Beckn.External.GoogleMaps.Types (Bounds, LocationS)
import Beckn.Product.MapSearch.PolyLinePoints
import Beckn.Types.App (Value)
import Beckn.Utils.GenericPretty (PrettyShow)
import Control.Lens.Operators
import Data.Geospatial
import Data.LineString
import Data.OpenApi
import EulerHS.Prelude

data LatLong = LatLong
  { lat :: Double,
    lon :: Double
  }
  deriving (Show, Generic, FromJSON, ToJSON, ToSchema, PrettyShow)

data TravelMode = CAR | MOTORCYCLE | BICYCLE | FOOT
  deriving (Show, Eq, Generic, ToJSON, FromJSON, ToSchema)

data Route = Route
  { durationInS :: Maybe Integer,
    distanceInM :: Maybe Double,
    boundingBox :: Bounds,
    snappedWaypoints :: [[(LocationS, LocationS)]],
    points :: [[[LatiLong]]]
  }
  deriving (Generic, ToJSON, FromJSON, ToSchema)

instance ToSchema BoundingBoxWithoutCRS where
  declareNamedSchema _ = do
    aSchema <- declareSchema (Proxy :: Proxy Value)
    return $
      NamedSchema (Just "BoundingBoxWithoutCRS") $
        aSchema
          & description
            ?~ "https://datatracker.ietf.org/doc/html/rfc7946#section-5"

instance ToSchema GeospatialGeometry where
  declareNamedSchema _ = do
    aSchema <- declareSchema (Proxy :: Proxy Value)
    return $
      NamedSchema (Just "GeospatialGeometry") $
        aSchema
          & description
            ?~ "https://datatracker.ietf.org/doc/html/rfc7946#section-2"

data Request = Request
  { waypoints :: NonEmpty LatLong,
    mode :: Maybe TravelMode, -- Defaults to CAR
    calcPoints :: Bool -- True (default) if points needs to be calculated
  }
  deriving (Generic, ToJSON, FromJSON, Show, ToSchema)

type Response = [Route]
