module Beckn.External.Graphhopper.Types where

import Data.Aeson
import Data.Geospatial hiding (bbox)
import EulerHS.Prelude hiding (Show)
import Prelude (Show (..))

data Weighting = FASTEST | SHORTEST | SHORT_FASTEST
  deriving (Show, Generic, ToJSON)

data Vehicle = CAR | BIKE | FOOT | HIKE | MTB | RACINGBIKE | SCOOTER | TRUCK | SMALL_TRUCK
  deriving (Show, Generic, ToJSON)

data Request = Request
  { points :: [GeoPositionWithoutCRS],
    vehicle :: Vehicle,
    weighting :: Maybe Weighting,
    elevation :: Maybe Bool,
    calc_points :: Maybe Bool,
    points_encoded :: Bool
  }
  deriving (Show, Generic)

instance ToJSON Request where
  toJSON = genericToJSON defaultOptions {omitNothingFields = True}

data Path = Path
  { distance :: Double, -- meters
    time :: Integer, -- miliseconds
    bbox :: Maybe BoundingBoxWithoutCRS, -- bbox and points fields are empty incase calcPoints
    points :: Maybe GeospatialGeometry, -- is set to False. Default - True
    snapped_waypoints :: GeospatialGeometry,
    transfers :: Integer,
    instructions :: Maybe [Instruction]
  }
  deriving (Generic, FromJSON, ToJSON, Show)

data Instruction = Instruction
  { distance :: Double,
    heading :: Maybe Double,
    sign :: Integer,
    interval :: [Integer],
    text :: String,
    time :: Int,
    street_name :: String
  }
  deriving (Generic, FromJSON, ToJSON, Show)

newtype Response = Response
  { paths :: [Path]
  }
  deriving (Generic, FromJSON, ToJSON, Show)
