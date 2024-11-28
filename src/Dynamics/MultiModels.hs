module Dynamics.MultiModels where

import Data.List.Split (chunksOf)
import Numeric.LinearAlgebra
import Type.Basic
import Type.Dynamics
import Numeric.AD

-- FIXME: Generalize players, states & input count
linearDynamics :: SystemDynamicsFunctionType -> StateControlData -> LinearMultiSystemDynamics
linearDynamics dyn cspair = LinearContinuousMultiSystemDynamics { systemMatrix = a, inputMatrices = bs }
  where
    x = priorState cspair
    u = controlInput cspair
    a = matrix 12 $ concat $ stateJacobian dyn (toList x) (toList u)
    ball = matrix 6 $ concat $ inputJacobian dyn (toList x) (toList u)
    bs = map (\p -> ball ?? (All, Pos (fromList p))) (chunksOf 2 [0..5])

-- FIXME: Generalize players, states & input count
multiPlayerSystem :: [[a] -> [a] -> [a]] -> [a] -> [a] -> [a]
multiPlayerSystem dyn xs us = concat (zipWith (\sys (x,u) -> sys x u) dyn xuv)
  where
    xuv = zip (chunksOf 4 xs) (chunksOf 2 us)

stateJacobian :: (Floating a) => SystemDynamicsFunctionType -> [a] -> [a] -> [[a]]
stateJacobian dyn x u = jacobian (\xs -> dyn xs (fmap auto u)) x

inputJacobian :: (Floating a) => SystemDynamicsFunctionType -> [a] -> [a] -> [[a]]
inputJacobian dyn x = jacobian (dyn (fmap auto x))