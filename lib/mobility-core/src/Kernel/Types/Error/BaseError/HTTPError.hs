{-# LANGUAGE TemplateHaskell #-}

module Kernel.Types.Error.BaseError.HTTPError
  ( module Kernel.Types.Error.BaseError.HTTPError,
    module Kernel.Types.Error.BaseError.HTTPError.HttpCode,
    module Kernel.Types.Error.BaseError.HTTPError.APIError,
    module Kernel.Types.Error.BaseError.HTTPError.BecknAPIError,
    module Kernel.Types.Error.BaseError,
    instanceExceptionWithParent,
  )
where

import Kernel.Types.Error.BaseError
import Kernel.Types.Error.BaseError.HTTPError.APIError
import Kernel.Types.Error.BaseError.HTTPError.BecknAPIError
import Kernel.Types.Error.BaseError.HTTPError.HttpCode
import Kernel.Utils.Error.Hierarchy (instanceExceptionWithParent)
import Control.Exception
import EulerHS.Prelude hiding (Show, pack, show)
import Network.HTTP.Types (Header)
import Prelude (Show (..))

type IsHTTPException e = (IsHTTPError e, IsAPIError e, IsBecknAPIError e, Exception e)

class IsBaseError e => IsHTTPError e where
  toErrorCode :: e -> Text

  toHttpCode :: e -> HttpCode
  toHttpCode _ = E500

  toCustomHeaders :: e -> [Header]
  toCustomHeaders _ = []

data HTTPException = forall e. (Exception e, IsHTTPException e) => HTTPException e

instance IsBaseError HTTPException where
  toMessage (HTTPException e) = toMessage e

instance IsHTTPError HTTPException where
  toErrorCode (HTTPException e) = toErrorCode e
  toHttpCode (HTTPException e) = toHttpCode e
  toCustomHeaders (HTTPException e) = toCustomHeaders e

instance Show HTTPException where
  show (HTTPException e) = show e

instanceExceptionWithParent 'BaseException ''HTTPException

toMessageIfNotInternal :: IsHTTPError e => e -> Maybe Text
toMessageIfNotInternal e = if isInternalError (toHttpCode e) then Nothing else toMessage e
