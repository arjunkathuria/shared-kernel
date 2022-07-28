module Beckn.Utils.Logging
  ( Log (..),
    LogLevel (..),
    log,
    logTagDebug,
    logTagInfo,
    logTagWarning,
    logTagError,
    logDebug,
    logInfo,
    logWarning,
    logError,
    withRandomId,
    withTransactionIdLogTag,
    withTransactionIdLogTag',
    withPersonIdLogTag,
    makeLogSomeException,
    logPretty,
    HasPrettyLogger,
  )
where

import Beckn.Types.Error.BaseError.HTTPError
import Beckn.Types.GuidLike (generateGUID)
import Beckn.Types.Id
import Beckn.Types.Logging
import Beckn.Types.MonadGuid
import Beckn.Utils.GenericPretty (PrettyShow, textPretty)
import EulerHS.Prelude hiding (id)
import GHC.Records.Extra

log :: Log m => LogLevel -> Text -> m ()
log = logOutput

logTagDebug :: Log m => Text -> Text -> m ()
logTagDebug tag = withLogTag tag . logOutput DEBUG

logTagInfo :: Log m => Text -> Text -> m ()
logTagInfo tag = withLogTag tag . logOutput INFO

logTagWarning :: Log m => Text -> Text -> m ()
logTagWarning tag = withLogTag tag . logOutput WARNING

logTagError :: Log m => Text -> Text -> m ()
logTagError tag = withLogTag tag . logOutput ERROR

logDebug :: Log m => Text -> m ()
logDebug = logOutput DEBUG

logInfo :: Log m => Text -> m ()
logInfo = logOutput INFO

logWarning :: Log m => Text -> m ()
logWarning = logOutput WARNING

logError :: Log m => Text -> m ()
logError = logOutput ERROR

withRandomId :: (MonadGuid m, Log m) => m b -> m b
withRandomId f = do
  id <- generateGUID
  withLogTag id f

withPersonIdLogTag :: Log m => Id b -> m a -> m a
withPersonIdLogTag personId = do
  withLogTag ("actor-" <> getId personId)

withTransactionIdLogTag :: (HasField "context" b c, HasField "transaction_id" c (Maybe Text), Log m) => b -> m a -> m a
withTransactionIdLogTag req =
  withTransactionIdLogTag' $ fromMaybe "Unknown" req.context.transaction_id

withTransactionIdLogTag' :: Log m => Text -> m a -> m a
withTransactionIdLogTag' txnId =
  withLogTag ("txnId-" <> txnId)

makeLogSomeException :: SomeException -> Text
makeLogSomeException someExc
  | Just (HTTPException err) <- fromException someExc = logHTTPError err
  | Just (BaseException err) <- fromException someExc =
    fromMaybe (show err) $ toMessage err
  | otherwise = show someExc
  where
    logHTTPError err =
      show (toHttpCode err)
        <> " "
        <> toErrorCode err
        <> maybe "" (": " <>) (toMessage err)

renderViaShow :: (Show a) => Text -> a -> Text
renderViaShow description val = description <> ": " <> show val

renderViaPrettyShow :: (PrettyShow a) => Text -> a -> Text
renderViaPrettyShow description val = description <> "\n" <> textPretty val

type HasPrettyLogger m env =
  ( Log m,
    MonadReader env m,
    HasField "loggerConfig" env LoggerConfig
  )

logPretty ::
  ( PrettyShow a,
    Show a,
    HasPrettyLogger m env
  ) =>
  LogLevel ->
  Text ->
  a ->
  m ()
logPretty logLevel description val = do
  pretty <- asks (.loggerConfig.prettyPrinting)
  let render =
        if pretty
          then renderViaPrettyShow
          else renderViaShow
  logOutput logLevel $ render description val
