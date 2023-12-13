{-
  Copyright 2022-23, Juspay India Pvt Ltd

  This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License

  as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. This program is

  distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS

  FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details. You should have received a copy of the GNU Affero

  General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
-}

module Kernel.Utils.Error.FlowHandling
  ( withFlowHandler,
    withFlowHandlerAPI,
    withFlowHandlerBecknAPI,
    apiHandler,
    becknApiHandler,
    someExceptionToBecknApiError,
    handleIfUp,
    throwServantError,
  )
where

import Control.Concurrent.STM (isEmptyTMVar)
import Control.Monad.Reader
import qualified Data.Aeson as A
import qualified EulerHS.Language as L
import EulerHS.Prelude
import GHC.Records.Extra
-- import Kernel.Tools.Metrics.CoreMetrics (HasCoreMetrics)

import Kernel.Beam.Lib.UtilsTH
import qualified Kernel.Beam.Types as KBT
import Kernel.Storage.Beam.SystemConfigs
import Kernel.Storage.Esqueleto.Config
import Kernel.Storage.Hedis.Config
import Kernel.Storage.Queries.SystemConfigs
import qualified Kernel.Tools.Metrics.CoreMetrics as Metrics
import Kernel.Tools.Metrics.CoreMetrics.Types
import Kernel.Types.App
import Kernel.Types.Beckn.Ack
import Kernel.Types.CacheFlow
import Kernel.Types.Common
import Kernel.Types.Error as Err
import Kernel.Types.Error.BaseError.HTTPError
import Kernel.Types.Flow
import Kernel.Utils.Error.BaseError.HTTPError.APIError (toAPIError)
import Kernel.Utils.Error.BaseError.HTTPError.BecknAPIError (toBecknAPIError)
import Kernel.Utils.Error.Throwing (fromMaybeM)
import Kernel.Utils.IOLogging
import Kernel.Utils.Logging
import Kernel.Utils.Text
import Network.HTTP.Types (Header, hContentType)
import Network.HTTP.Types.Header (HeaderName)
import Servant (ServerError (..))

withFlowHandler ::
  ( -- CacheFlow (FlowHandlerR r) (r),
    HasField "cacheConfig" r CacheConfig,
    HasField "enablePrometheusMetricLogging" r Bool,
    HasField "enableRedisLatencyLogging" r Bool,
    HasField "coreMetrics" r CoreMetricsContainer,
    HasField "hedisClusterEnv" r HedisEnv,
    HasField "hedisEnv" r HedisEnv,
    HasField "hedisNonCriticalClusterEnv" r HedisEnv,
    HasField "hedisNonCriticalEnv" r HedisEnv,
    HasField "hedisMigrationStage" r Bool,
    HasField "esqDBEnv" r EsqDBEnv,
    HasField "loggerEnv" r LoggerEnv,
    HasField "version" r DeploymentVersion,
    HasSchemaName SystemConfigsT
  ) =>
  FlowR r a ->
  FlowHandlerR r a
withFlowHandler flow = do
  (EnvR flowRt appEnv) <- ask
  liftIO . runFlowR flowRt appEnv $
    findById "kv_configs"
      >>= pure . decodeFromText @Tables
      >>= fromMaybeM (InternalError "Decoding failed")
      >>= L.setOptionLocal KBT.Tables
      >> flow

withFlowHandlerAPI ::
  ( -- CacheFlow (FlowHandlerR r) r,
    HasField "cacheConfig" r CacheConfig,
    HasField "enablePrometheusMetricLogging" r Bool,
    HasField "enableRedisLatencyLogging" r Bool,
    HasField "coreMetrics" r CoreMetricsContainer,
    HasField "hedisClusterEnv" r HedisEnv,
    HasField "hedisEnv" r HedisEnv,
    HasField "hedisNonCriticalClusterEnv" r HedisEnv,
    HasField "hedisNonCriticalEnv" r HedisEnv,
    HasField "hedisMigrationStage" r Bool,
    HasField "esqDBEnv" r EsqDBEnv,
    HasField "loggerEnv" r LoggerEnv,
    HasField "version" r DeploymentVersion,
    -- EsqDBFlow (FlowHandlerR r) (EnvR r),
    HasSchemaName SystemConfigsT,
    Metrics.CoreMetrics (FlowR r),
    HasField "isShuttingDown" r (TMVar ()),
    Log (FlowR r)
  ) =>
  FlowR r a ->
  FlowHandlerR r a
withFlowHandlerAPI = withFlowHandler . apiHandler . handleIfUp

withFlowHandlerBecknAPI ::
  ( -- CacheFlow (FlowHandlerR r) r,
    -- EsqDBFlow (FlowHandlerR r) (EnvR r),
    HasField "cacheConfig" r CacheConfig,
    HasField "enablePrometheusMetricLogging" r Bool,
    HasField "enableRedisLatencyLogging" r Bool,
    HasField "coreMetrics" r CoreMetricsContainer,
    HasField "hedisClusterEnv" r HedisEnv,
    HasField "hedisEnv" r HedisEnv,
    HasField "hedisNonCriticalClusterEnv" r HedisEnv,
    HasField "hedisNonCriticalEnv" r HedisEnv,
    HasField "hedisMigrationStage" r Bool,
    HasField "esqDBEnv" r EsqDBEnv,
    HasField "loggerEnv" r LoggerEnv,
    HasField "version" r DeploymentVersion,
    HasCoreMetrics r,
    HasField "isShuttingDown" r (TMVar ()),
    Log (FlowR r),
    HasSchemaName SystemConfigsT
  ) =>
  FlowR r AckResponse ->
  FlowHandlerR r AckResponse
withFlowHandlerBecknAPI = withFlowHandler . becknApiHandler . handleIfUp

handleIfUp ::
  ( L.MonadFlow m,
    Log m,
    MonadReader r m,
    HasField "isShuttingDown" r (TMVar ()),
    Metrics.CoreMetrics m
  ) =>
  m a ->
  m a
handleIfUp flow = do
  shutdown <- asks (.isShuttingDown)
  shouldRun <- L.runIO $ atomically $ isEmptyTMVar shutdown
  if shouldRun
    then flow
    else throwAPIError ServerUnavailable

apiHandler ::
  ( MonadCatch m,
    Log m,
    Metrics.CoreMetrics m
  ) =>
  m a ->
  m a
apiHandler = (`catch` someExceptionToAPIErrorThrow)

becknApiHandler ::
  ( MonadCatch m,
    Log m,
    Metrics.CoreMetrics m
  ) =>
  m a ->
  m a
becknApiHandler = (`catch` someExceptionToBecknApiErrorThrow)

someExceptionToAPIErrorThrow ::
  ( MonadCatch m,
    Log m,
    Metrics.CoreMetrics m
  ) =>
  SomeException ->
  m a
someExceptionToAPIErrorThrow exc
  | Just (HTTPException err) <- fromException exc = throwAPIError err
  | Just (BaseException err) <- fromException exc =
    throwAPIError . InternalError . fromMaybe (show err) $ toMessage err
  | otherwise = throwAPIError . InternalError $ show exc

someExceptionToBecknApiErrorThrow ::
  ( MonadCatch m,
    Log m,
    Metrics.CoreMetrics m
  ) =>
  SomeException ->
  m a
someExceptionToBecknApiErrorThrow exc
  | Just (HTTPException err) <- fromException exc = throwBecknApiError err
  | otherwise =
    throwBecknApiError . InternalError $ show exc

someExceptionToBecknApiError :: SomeException -> BecknAPIError
someExceptionToBecknApiError exc
  | Just (HTTPException err) <- fromException exc = toBecknAPIError err
  | otherwise = toBecknAPIError . InternalError $ show exc

throwAPIError ::
  ( Log m,
    MonadThrow m,
    IsHTTPException e,
    Exception e,
    Metrics.CoreMetrics m
  ) =>
  e ->
  m a
throwAPIError = throwHTTPError toAPIError

throwBecknApiError ::
  ( Log m,
    MonadThrow m,
    IsHTTPException e,
    Exception e,
    Metrics.CoreMetrics m
  ) =>
  e ->
  m a
throwBecknApiError = throwHTTPError toBecknAPIError

throwHTTPError ::
  ( ToJSON j,
    Log m,
    MonadThrow m,
    IsHTTPException e,
    Exception e,
    Metrics.CoreMetrics m
  ) =>
  (e -> j) ->
  e ->
  m b
throwHTTPError toJsonError err = do
  let someExc = toException err
  logError $ makeLogSomeException someExc
  Metrics.incrementErrorCounter "DEFAULT_ERROR" someExc
  throwServantError (toHttpCode err) (toCustomHeaders err) (toJsonError err)

throwServantError ::
  (ToJSON a, Log m, MonadThrow m) =>
  HttpCode ->
  [Header] ->
  a ->
  m b
throwServantError httpCode customHeaders jsonError = withLogTag "HTTP_ERROR" $ do
  let body = A.encode jsonError
  let serverErr = toServerError httpCode
  throwM
    serverErr
      { errBody = body,
        errHeaders = jsonHeader : customHeaders ++ errHeaders serverErr
      }
  where
    jsonHeader :: (HeaderName, ByteString)
    jsonHeader = (hContentType, "application/json;charset=utf-8")
