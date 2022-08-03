module Main where

import APIExceptions
import Amount
import EulerHS.Prelude
import SignatureAuth
import SlidingWindowLimiter
import Test.Tasty
import DistanceCalculation

main :: IO ()
main = defaultMain =<< specs

specs :: IO TestTree
specs = return $ testGroup "Tests" [unitTests]
  where
    unitTests =
      testGroup
        "Unit tests"
        [ amountTests,
          signatureAuthTests,
          httpExceptionTests,
          slidingWindowLimiterTests,
          distanceCalculation
        ]
