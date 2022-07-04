{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TemplateHaskell #-}
{-# OPTIONS_GHC -Wno-orphans #-}

module Beckn.Scheduler.Storage.Tabular where

import Beckn.Prelude
import qualified Beckn.Scheduler.Types as ST
import Beckn.Storage.Esqueleto
import Beckn.Types.Id

derivePersistField "ST.JobStatus"

mkPersist
  defaultSqlSettings
  [defaultQQ|
    JobT sql=job
      id Text
      jobType Text
      jobData Text
      scheduledAt UTCTime
      createdAt UTCTime
      updatedAt UTCTime
      maxErrors Int
      currErrors Int
      status ST.JobStatus
      Primary id
      deriving Generic
    |]

instance TEntityKey JobT where
  type DomainKey JobT = Id (ST.Job Text Text)
  fromKey (JobTKey _id) = Id _id
  toKey (Id id) = JobTKey id

instance TType JobT ST.JobText where
  fromTType JobT {..} = do
    pure $
      ST.Job
        { id = Id id,
          ..
        }
  toTType ST.Job {..} =
    JobT
      { id = getId id,
        ..
      }
