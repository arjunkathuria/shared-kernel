module Beckn.Types.Core.Taxi.OnUpdate.OnUpdateEvent.RideBookingCancelledEvent
  ( module Beckn.Types.Core.Taxi.OnUpdate.OnUpdateEvent.RideBookingCancelledEvent,
    module Reexport,
  )
where

import Beckn.Prelude
import Beckn.Types.Core.Taxi.Common.CancellationSource as Reexport
import Beckn.Types.Core.Taxi.OnUpdate.OnUpdateEvent.OnUpdateEventType (OnUpdateEventType (RIDE_BOOKING_CANCELLED))
import qualified Control.Lens as L
import Data.Aeson as A
import Data.OpenApi hiding (Example, example, name)
import GHC.Exts (fromList)

data RideBookingCancelledEvent = RideBookingCancelledEvent
  { id :: Text,
    update_target :: Text,
    state :: Text,
    cancellation_reason :: CancellationSource
  }
  deriving (Generic, Show)

instance ToJSON RideBookingCancelledEvent where
  toJSON RideBookingCancelledEvent {..} =
    A.Object $
      "id" .= id
        <> "./komn/update_target" .= update_target
        <> "state" .= state
        <> "./komn/cancellation_reason" .= cancellation_reason
        <> "fulfillment" .= (("state" .= (("code" .= RIDE_BOOKING_CANCELLED) :: A.Object)) :: A.Object)

instance FromJSON RideBookingCancelledEvent where
  parseJSON = withObject "RideBookingCancelledEvent" $ \obj -> do
    update_type <- (obj .: "fulfillment") >>= (.: "state") >>= (.: "code")
    unless (update_type == RIDE_BOOKING_CANCELLED) $ fail "Wrong update_type."
    RideBookingCancelledEvent
      <$> obj .: "id"
      <*> obj .: "./komn/update_target"
      <*> obj .: "state"
      <*> obj .: "./komn/cancellation_reason"

instance ToSchema RideBookingCancelledEvent where
  declareNamedSchema _ = do
    txt <- declareSchemaRef (Proxy :: Proxy Text)
    cancellationSource <- declareSchemaRef (Proxy :: Proxy CancellationSource)
    update_type <- declareSchemaRef (Proxy :: Proxy OnUpdateEventType)
    let st =
          mempty
            & type_ L.?~ OpenApiObject
            & properties
              L..~ fromList
                [("code", update_type)]
            & required L..~ ["code"]
        fulfillment =
          mempty
            & type_ L.?~ OpenApiObject
            & properties
              L..~ fromList
                [("state", Inline st)]
            & required L..~ ["state"]
    return $
      NamedSchema (Just "RideBookingCancelledEvent") $
        mempty
          & type_ L.?~ OpenApiObject
          & properties
            L..~ fromList
              [ ("id", txt),
                ("./komn/update_target", txt),
                ("state", txt),
                ("./komn/cancellation_reason", cancellationSource),
                ("fulfillment", Inline fulfillment)
              ]
          & required
            L..~ [ "id",
                   "./komn/update_target",
                   "state",
                   "./komn/cancellation_reason",
                   "fulfillment"
                 ]
