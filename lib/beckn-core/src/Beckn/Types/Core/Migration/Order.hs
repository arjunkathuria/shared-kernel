module Beckn.Types.Core.Migration.Order where

import Beckn.Types.Common (IdObject)
import Beckn.Types.Core.Migration.Billing
import Beckn.Types.Core.Migration.Fulfillment (Fulfillment)
import Beckn.Types.Core.Migration.ItemQuantity
import Beckn.Types.Core.Migration.Payment
import Beckn.Types.Core.Migration.Quotation
import Beckn.Utils.Example
import Data.Time
import EulerHS.Prelude hiding (State, id, state)

data Order = Order
  { id :: Maybe Text,
    state :: Maybe Text,
    items :: [OrderItem],
    add_ons :: [IdObject],
    offers :: [IdObject],
    billing :: Billing,
    fulfillment :: Fulfillment,
    quote :: Quotation,
    payment :: Payment,
    created_at :: Maybe UTCTime,
    updated_at :: Maybe UTCTime
  }
  deriving (Generic, FromJSON, ToJSON, Show)

data OrderItem = OrderItem
  { id :: Text,
    quantity :: ItemQuantity
  }
  deriving (Generic, FromJSON, ToJSON, Show)

instance Example Order where
  example =
    Order
      { id = Nothing,
        state = Nothing,
        items = [],
        add_ons = [],
        offers = [],
        billing = example,
        fulfillment = example,
        quote = example,
        payment = example,
        created_at = Nothing,
        updated_at = Nothing
      }

newtype OrderObject = OrderObject
  { order :: Order
  }
  deriving (Generic, Show, FromJSON, ToJSON)
