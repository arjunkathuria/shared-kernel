module Beckn.Types.Logging where

import Beckn.Utils.Dhall (FromDhall)
import EulerHS.Prelude

data LogLevel = DEBUG | INFO | WARNING | ERROR
  deriving (Generic, Show, Eq, Ord, FromDhall, ToJSON)

class Log m where
  logOutput :: LogLevel -> Text -> m ()
  withLogTag :: Text -> m a -> m a

data LoggerConfig = LoggerConfig
  { level :: LogLevel,
    logToFile :: Bool,
    logFilePath :: FilePath,
    logToConsole :: Bool,
    logRawSql :: Bool,
    prettyPrinting :: Bool
  }
  deriving (Generic, FromDhall)

defaultLoggerConfig :: LoggerConfig
defaultLoggerConfig =
  LoggerConfig
    { level = DEBUG,
      logFilePath = "/tmp/default",
      logToFile = False,
      logToConsole = False,
      logRawSql = False,
      prettyPrinting = False
    }
