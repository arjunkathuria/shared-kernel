module Kernel.Exit where

import System.Exit (ExitCode (..))

exitSuccess :: ExitCode
exitSuccess = ExitSuccess

exitAuthManagerPrepFailure :: ExitCode
exitAuthManagerPrepFailure = ExitFailure 1

exitDBConnPrepFailure :: ExitCode
exitDBConnPrepFailure = ExitFailure 2

exitDBMigrationFailure :: ExitCode
exitDBMigrationFailure = ExitFailure 3

exitLoadAllProvidersFailure :: ExitCode
exitLoadAllProvidersFailure = ExitFailure 4

exitRedisConnPrepFailure :: ExitCode
exitRedisConnPrepFailure = ExitFailure 5

exitConnCheckFailure :: ExitCode
exitConnCheckFailure = ExitFailure 8

exitBuildingAppEnvFailure :: ExitCode
exitBuildingAppEnvFailure = ExitFailure 9
