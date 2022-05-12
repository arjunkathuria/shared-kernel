module Beckn.Types.Core.Migration.Contact (Contact (..)) where

import Beckn.Types.Core.Migration.Tags (Tags)
import EulerHS.Prelude

data Contact = Contact
  { phone :: Maybe Text,
    email :: Maybe Text,
    tags :: Maybe Tags
  }
  deriving (Generic, FromJSON, ToJSON, Show)
