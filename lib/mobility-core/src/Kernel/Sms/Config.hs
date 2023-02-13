module Kernel.Sms.Config where

import EulerHS.Prelude
import Kernel.Utils.Dhall (FromDhall)
import Servant.Client (BaseUrl)

data SmsSessionConfig = SmsSessionConfig
  { attempts :: Int,
    authExpiry :: Int,
    tokenExpiry :: Int
  }
  deriving (Generic, FromDhall)

data SmsCredConfig = SmsCredConfig
  { username :: Text, -- FIXME? Do we need to reuse Servant's one?
    password :: Text, -- idem
    otpHash :: Text
  }
  deriving (Generic, FromDhall)

data SmsConfig = SmsConfig
  { sessionConfig :: SmsSessionConfig,
    credConfig :: SmsCredConfig,
    useFakeSms :: Maybe Word16, -- 4 digit
    url :: BaseUrl,
    sender :: Text
  }
  deriving (Generic, FromDhall)