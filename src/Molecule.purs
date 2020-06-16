module MolDraw.Molecule
( Molecule
) where

import Prelude
import Data.Int as I
import Data.Number as N
import Data.Map (Map, insert)
import Data.List (List)
import Data.Tuple (Tuple(Tuple))
import Data.Maybe (Maybe (Just, Nothing))
import Data.Array (filter)
import Data.String (length)
import Data.String.Utils (words, includes)
import MolDraw.Atom (Atom, atom)
import MolDraw.Position (Position(Position))
import MolDraw.BondSegment (BondSegment)
import MolDraw.ChemicalSymbol (chemicalSymbol)

data Molecule = Molecule

data V3000State = NotReading | ReadingAtoms | ReadingBonds

data V3000Content = V3000Content
    { atoms        :: Map Int Atom
    , bondSegments :: List BondSegment
    , state        :: V3000State
    }



v3000Parser :: V3000Content -> String -> Maybe V3000Content
v3000Parser
    state@(V3000Content { atoms, bondSegments, state: ReadingAtoms })
    line
        | includes "M  V30 END ATOM" line =
            Just
                (V3000Content
                    { atoms: atoms
                    , bondSegments: bondSegments
                    , state: NotReading
                    }
                )

        | otherwise = case parseAtom line of
            Just (Tuple id atom) -> Just (addAtom state id atom)
            Nothing -> Nothing


v3000Parser
    state@(V3000Content { atoms, bondSegments, state: ReadingBonds })
    line
    = Just state
--
--    | includes "M  V30 END BOND" line =
--        Just
--            (NotReading
--                { atoms: atoms
--                , bondSegments: bondSegments
--                , state: NotReading
--                }
--            )
--
--    | otherwise =
--        case parseBond line of
--            (Just bond) -> Just (addBond state bond)
--            Nothing -> Nothing


v3000Parser
    state@(V3000Content { atoms, bondSegments, state: NotReading })
    line

        | includes "M  V30 BEGIN ATOM" line =
            Just
                (V3000Content
                    { atoms: atoms
                    , bondSegments: bondSegments
                    , state: ReadingAtoms
                    }
                )

    --    | includes "M  V30 BEGIN BOND" line =
    --        Just
    --            (V3000Content
    --                { atoms: atoms
    --                , bondSegments: bondSegments
    --                , state: ReadingBonds
    --                }
    --            )

        | otherwise = Just state



words' :: String -> Array String
words' = filter ((>) 0 <<< length) <<< words



parseAtom :: String -> Maybe (Tuple Int Atom)
parseAtom line = readAtom $ words' line



readAtom :: Array String -> Maybe (Tuple Int Atom)
readAtom [_, id, element, x, y, z] = do
    symbol <- chemicalSymbol element
    id'    <- I.fromString id
    x'     <- N.fromString x
    y'     <- N.fromString y
    z'     <- N.fromString z

    let atom' = atom symbol (Position x' y' z')

    Just (Tuple id' atom')

readAtom _ = Nothing



addAtom :: V3000Content -> Int -> Atom -> V3000Content
addAtom (V3000Content { atoms, bondSegments, state }) id atom =
    V3000Content
    { atoms: insert id atom atoms
    , bondSegments: bondSegments
    , state: state
    }
