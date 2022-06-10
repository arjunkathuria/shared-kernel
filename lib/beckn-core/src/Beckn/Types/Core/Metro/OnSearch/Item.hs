module Beckn.Types.Core.Metro.OnSearch.Item where

import Beckn.Types.Core.Metro.OnSearch.Descriptor (Descriptor)
import Beckn.Types.Core.Metro.OnSearch.Price (Price)
import Data.OpenApi (ToSchema)
import Data.Time (UTCTime)
import EulerHS.Prelude hiding (id)

data Item = Item
  { id :: Text,
    descriptor :: Descriptor,
    price :: Price,
    location_id :: Text,
    stops :: [Stop]
  }
  deriving (Generic, FromJSON, ToJSON, Show, ToSchema)

data Stop = Stop
  { id :: Text,
    time :: ScheduleObj
  }
  deriving (Generic, FromJSON, ToJSON, Show, ToSchema)

newtype ScheduleObj = ScheduleObj {schedule :: TimeObj}
  deriving (Generic, FromJSON, ToJSON, Show, ToSchema)

newtype TimeObj = TimeObj {times :: [UTCTime]}
  deriving (Generic, FromJSON, ToJSON, Show, ToSchema)
