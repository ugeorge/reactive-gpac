{-# LANGUAGE FlexibleContexts, ExistentialQuantification #-}

module ForSyDe.Reactive.CoreTypeCT where

-- | We represent time as doubles even tough this is not the best
-- representation. For now we are interested in establishing the
-- framework.
type Time = Double

-- | The outputs of our processes will be doubles as well, but it will
-- be better to change latter to the same representation used for
-- Time.
-- newtype Value = Double

-- | Signals are functions over Time.
--data SignalCT a = SignalCT (Time -> (a, SignalCT a))

-- | Processes are functions over signals.
data PCT a b = PCT {prCT :: Time -> a -> ContCT a b}

-- | The Continuation data type encapsulates the output of the process
-- and a new Process for later computations.
type ContCT a b = (b, PCT a b)

-- | Sources have no input.
type SourceCT a = PCT () a

-- | API:

-- | 'at' observes a PCT at a specified time t.
at :: PCT () a -> Time -> a
p `at` t = fst $ prCT p t ()

--next :: SignalCT a -> Time -> SignalCT a
--next (SignalCT f) t = snd $ f t

-- | Composition operators.
liftCT :: (a -> b) -> PCT a b
liftCT f = PCT {prCT = \_ a -> (f a, liftCT f)}

cascadeCT :: PCT a b
          -> PCT b c
          -> PCT a c
cascadeCT (PCT {prCT = p1}) (PCT {prCT = p2}) =
  PCT {prCT = p}
  where
    p t a = (c, p1' `cascadeCT` p2')
      where
        (b, p1') = p1 t a
        (c, p2') = p2 t b

(>>>*) :: PCT a b
       -> PCT b c
       -> PCT a c
(>>>*) = cascadeCT

(<<<*) :: PCT b c
       -> PCT a b
       -> PCT a c
p1 <<<* p2 = cascadeCT p2 p1

firstCT :: PCT a b
        -> PCT (a, c) (b, c)
firstCT (PCT {prCT = p1}) = PCT {prCT = p}
  where
    p t (a,c) = ((b,c), firstCT p')
      where
        (b, p') = p1 t a

secondCT :: PCT a b
         -> PCT (c, a) (c, b)
secondCT (PCT {prCT = p1}) = PCT {prCT = p}
  where
    p t (c,a) = ((c,b), secondCT p')
      where
        (b, p') = p1 t a

-- | Parallel composition
splitCT :: PCT a b
        -> PCT c d
        -> PCT (a,c) (b,d)
splitCT (PCT {prCT = p1}) (PCT {prCT = p2}) =
  PCT {prCT = p}
  where
    p t (a,c) = ((b,d), splitCT p1' p2')
      where
        (b, p1') = p1 t a
        (d, p2') = p2 t c

feedCT :: PCT a b
       -> PCT a (b,b)
feedCT (PCT {prCT = p1}) = PCT {prCT = p}
  where
    p t a = ((b,b), feedCT p1')
      where
        (b, p1') = p1 t a
