{-# LANGUAGE DerivingVia #-}

module Beckn.Types.Core.Migration.Domain (Domain (..)) where

import Beckn.Utils.Example
import Beckn.Utils.GenericPretty
import Beckn.Utils.JSON (constructorsWithHyphensUntagged)
import qualified Control.Lens as L
import Data.Aeson
import Data.Aeson.Types (typeMismatch)
import Data.OpenApi hiding (Example)
import EulerHS.Prelude

data Domain
  = MOBILITY
  | FINAL_MILE_DELIVERY
  | LOCAL_RETAIL
  | FOOD_AND_BEVERAGE
  | HEALTHCARE
  | METRO
  | PARKING
  | PUBLIC_TRANSPORT
  | UNKNOWN_DOMAIN Text
  deriving (Eq, Generic, Show)
  deriving (PrettyShow) via Showable Domain

instance ToSchema Domain where
  declareNamedSchema _ = do
    return $
      NamedSchema (Just "Domain") $
        mempty
          & type_ L.?~ OpenApiString
          & enum_
            L.?~ [ "MOBILITY",
                   "FINAL_MILE_DELIVERY",
                   "LOCAL_RETAIL",
                   "FOOD_AND_BEVERAGE",
                   "HEALTHCARE",
                   "METRO",
                   "PARKING",
                   "PUBLIC_TRANSPORT"
                 ]

instance ToJSON Domain where
  toJSON MOBILITY = String "nic2004:60221"
  toJSON LOCAL_RETAIL = String "nic2004:52110"
  toJSON FINAL_MILE_DELIVERY = String "nic2004:55204"
  toJSON METRO = String "nic2004:60212"
  toJSON PARKING = String "nic2004:63031"
  toJSON PUBLIC_TRANSPORT = String "nic2004:63032"
  toJSON (UNKNOWN_DOMAIN domain) = String domain
  toJSON val = genericToJSON constructorsWithHyphensUntagged val -- TODO: update remaining domains with codes

instance FromJSON Domain where
  parseJSON (String "nic2004:60221") = pure MOBILITY
  parseJSON (String "nic2004:52110") = pure LOCAL_RETAIL
  parseJSON (String "nic2004:55204") = pure FINAL_MILE_DELIVERY
  parseJSON (String "FOOD-AND-BEVERAGE") = pure FOOD_AND_BEVERAGE
  parseJSON (String "HEALTHCARE") = pure HEALTHCARE
  parseJSON (String "nic2004:60212") = pure METRO
  parseJSON (String "nic2004:63031") = pure PARKING
  parseJSON (String "nic2004:63032") = pure PUBLIC_TRANSPORT
  parseJSON (String domain) = pure $ UNKNOWN_DOMAIN domain
  parseJSON e = typeMismatch "Core Domain" e

instance Example Domain where
  example = MOBILITY
