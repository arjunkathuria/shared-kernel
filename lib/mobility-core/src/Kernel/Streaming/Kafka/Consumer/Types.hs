module Kernel.Streaming.Kafka.Consumer.Types
  ( KafkaConsumerCfg (..),
    KafkaConsumerTools,
    HasKafkaConsumer,
    buildKafkaConsumerTools,
    releaseKafkaConsumerTools,
    module Reexport,
  )
where

import Kernel.Streaming.Kafka.Commons as Reexport
import Kernel.Streaming.Kafka.HasKafkaTopics
import Kernel.Types.Error
import Kernel.Utils.Dhall (FromDhall)
import EulerHS.Prelude
import GHC.Records.Extra (HasField)
import Kafka.Consumer hiding (ConsumerGroupId, groupId)
import qualified Kafka.Consumer as Consumer

type HasKafkaConsumer env r = HasField "kafkaConsumerEnv" r env

type ConsumerGroupId = Text

data KafkaConsumerCfg = KafkaConsumerCfg
  { brokers :: KafkaBrokersList,
    groupId :: ConsumerGroupId,
    timeoutMilliseconds :: Int
  }
  deriving (Generic, FromDhall)

data KafkaConsumerTools a = KafkaConsumerTools
  { kafkaConsumerCfg :: KafkaConsumerCfg,
    consumer :: Consumer.KafkaConsumer
  }
  deriving (Generic)

consumerProps :: KafkaConsumerCfg -> ConsumerProperties
consumerProps kafkaConsumerCfg =
  brokersList castBrokers
    <> Consumer.groupId (Consumer.ConsumerGroupId kafkaConsumerCfg.groupId)
    <> logLevel KafkaLogDebug
  where
    castBrokers = BrokerAddress <$> kafkaConsumerCfg.brokers

consumerSub :: [KafkaTopic] -> Subscription
consumerSub topicList =
  Consumer.topics castTopics
    <> offsetReset Earliest
  where
    castTopics = TopicName <$> topicList

buildKafkaConsumerTools :: forall a. HasKafkaTopics a => KafkaConsumerCfg -> IO (KafkaConsumerTools a)
buildKafkaConsumerTools kafkaConsumerCfg = do
  consumer <-
    newConsumer (consumerProps kafkaConsumerCfg) (consumerSub $ getTopics @a)
      >>= either (throwM . KafkaUnableToBuildTools) return

  return $ KafkaConsumerTools {..}

releaseKafkaConsumerTools :: KafkaConsumerTools a -> IO ()
releaseKafkaConsumerTools kafkaConsumerTools =
  closeConsumer kafkaConsumerTools.consumer
    >>= flip whenJust (throwM . KafkaUnableToReleaseTools)
