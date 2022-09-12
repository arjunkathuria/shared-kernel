module Beckn.Mock.Utils (module Beckn.Mock.Utils, maybeToEither) where

import Beckn.Types.Core.Error
import Data.Aeson hiding (Error)
import qualified Data.Aeson as Ae
import qualified Data.Aeson.Types as Ae
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as BSL
import Data.Either.Extra
import Data.List
import Data.String.Conversions
import qualified Data.Text as T
import Data.Time
import System.Random
import Universum

-- | Read formatted time.
-- Here %F means the same as %Y-%m-%d, and %R acts like %H:%M.
-- Example: readUTCTime "2021-12-01 18:00"
readUTCTime :: Text -> Maybe UTCTime
readUTCTime = parseTimeM True defaultTimeLocale "%F %R" . T.unpack

textToError :: Text -> Error
textToError desc =
  Error
    { _type = CORE_ERROR,
      code = "400",
      path = Nothing,
      message = Just desc
    }

generateOrderId :: (MonadIO m) => m Text
generateOrderId = fmap show $ liftIO $ randomRIO (1000000, 9999999 :: Int)

whenRight :: Applicative m => Either e a -> (a -> m ()) -> m ()
whenRight eith f = either (\_ -> pure ()) f eith

encodeJSON :: (ToJSON a) => a -> BSL.ByteString
encodeJSON = Ae.encode . toJSON

decodeJSON :: (FromJSON a) => BS.ByteString -> Maybe a
decodeJSON bs = Ae.decode (BSL.fromStrict bs) >>= Ae.parseMaybe parseJSON

decodingErrorMessage :: BS.ByteString -> Text
decodingErrorMessage bs = "failed to decode JSON: " <> cs bs

decodeEitherJSON :: (FromJSON a) => BS.ByteString -> Either Text a
decodeEitherJSON bs = do
  val <- maybeToEither (decodingErrorMessage bs) (Ae.decode (BSL.fromStrict bs))
  first T.pack $ Ae.parseEither parseJSON val

findAndDecode :: (FromJSON a) => BS.ByteString -> [(BS.ByteString, BS.ByteString)] -> Either Text a
findAndDecode key list = maybeToEither errMsg (lookup key list) >>= decodeEitherJSON
  where
    errMsg = "failed to find key: " <> cs key
