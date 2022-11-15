module Beckn.Storage.Esqueleto
  ( module Types,
    module Functions,
    module Queries,
    module Logger,
    module Config,
    module SqlDB,
    module Class,
    module Reexport,
    module Transactionable,
    module DTypeBuilder,
    defaultQQ,
    defaultSqlSettings,
  )
where

import Beckn.Storage.Esqueleto.Class as Class (SolidType, TEntityKey (..), TType (..), extractSolidType)
import Beckn.Storage.Esqueleto.Config as Config (EsqDBFlow, EsqDBReplicaFlow)
import Beckn.Storage.Esqueleto.DTypeBuilder as DTypeBuilder (DTypeBuilder, buildDType)
import Beckn.Storage.Esqueleto.Functions as Functions
import Beckn.Storage.Esqueleto.Logger as Logger (LoggerIO)
import Beckn.Storage.Esqueleto.Queries as Queries
import Beckn.Storage.Esqueleto.SqlDB as SqlDB
import Beckn.Storage.Esqueleto.Transactionable as Transactionable
import Beckn.Storage.Esqueleto.Types as Types
import Beckn.Utils.Text
import qualified Data.Text as T
import Database.Persist.Quasi.Internal
import Database.Persist.TH as Reexport
import EulerHS.Prelude hiding (Key)
import Language.Haskell.TH.Quote

defaultQQ :: QuasiQuoter
defaultQQ =
  persistWith $
    upperCaseSettings
      { psToDBName = camelCaseToSnakeCase
      }

defaultSqlSettings :: MkPersistSettings
defaultSqlSettings =
  sqlSettings
    { mpsConstraintLabelModifier = \tableName fieldName ->
        if T.last tableName /= 'T'
          then "Table_name_must_end_with_T"
          else T.init tableName <> fieldName,
      mpsFieldLabelModifier = \_ fieldName -> fieldName
    }
