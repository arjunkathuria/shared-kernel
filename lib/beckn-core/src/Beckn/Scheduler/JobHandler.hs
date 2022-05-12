module Beckn.Scheduler.JobHandler where

import Beckn.Prelude
import Beckn.Scheduler.Types

data JobHandler t = forall d.
  JobDataConstraints d =>
  JobHandler
  { handlerFunc :: Job t d -> IO ExecutionResult
  }

type JobHandlerList t = [(t, JobHandler t)]
