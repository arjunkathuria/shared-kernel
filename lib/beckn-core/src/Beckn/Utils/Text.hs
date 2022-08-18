module Beckn.Utils.Text where

import qualified Data.Aeson as A
import qualified Data.ByteString.Lazy as BSL
import qualified Data.Char as Char
import qualified Data.Text as T
import qualified Data.Text.Encoding as DT
import EulerHS.Prelude

compareWithoutRightSpaces :: Text -> Text -> Bool
compareWithoutRightSpaces = (==) `on` T.dropWhileEnd Char.isSpace

decodeFromText :: FromJSON a => Text -> Maybe a
decodeFromText = A.decode . BSL.fromStrict . DT.encodeUtf8

encodeToText :: ToJSON a => a -> Text
encodeToText = DT.decodeUtf8 . BSL.toStrict . A.encode

padLeft :: Int -> Char -> Text -> Text
padLeft n c txt = T.replicate (max 0 $ n - length txt) (T.singleton c) <> txt

-- Suits only for non-negative numbers
padNumber :: Integral i => Int -> i -> Text
padNumber n num = padLeft n '0' $ show (fromIntegral num :: Natural)

recursiveStrip :: String -> String
recursiveStrip = \case
  ('_' : xs) -> recursiveStrip xs
  a -> a

maskText :: Text -> Text
maskText text =
  if length text > 6
    then T.take 3 text <> "..." <> T.takeEnd 3 text
    else "..."

truncateText :: Text -> Text 
truncateText text = 
  if length text > 100000 -- TODO: Change this to mutually decided value
    then T.take 100 text <> "..."
    else text

camelCaseToSnakeCase :: Text -> Text
camelCaseToSnakeCase =
  T.concatMap \c ->
    if Char.isUpper c then T.pack ['_', Char.toLower c] else T.singleton c
