module MolDraw.Parsers.V3000
( parseV3000
, V3000Content
, atoms
, bondSegments
) where


import Prelude
import Data.Int as I
import Data.Number as N
import Data.Map (Map, insert, empty, lookup, values)
import Data.List (List (Nil), (:), fromFoldable)
import Data.Tuple (Tuple(Tuple))
import Data.Either (Either(Left, Right))
import Data.Array (filter, foldl)
import Data.String (length)
import Data.String.Utils (lines, words, includes)
import MolDraw.GeometryAtom (GeometryAtom, atom)
import MolDraw.Position (Position(Position))
import MolDraw.BondSegment as BS
import MolDraw.Parsers.ChemicalSymbol (chemicalSymbol)
import MolDraw.Utils (toEither)


data V3000State = NotReading | ReadingAtoms | ReadingBonds


instance showV3000State :: Show V3000State where
    show NotReading   = "NotReading"
    show ReadingAtoms = "ReadingAtoms"
    show ReadingBonds = "ReadingBonds"


data V3000Content = V3000Content
    { _atoms        :: Map Int GeometryAtom
    , _bondSegments :: List BS.BondSegment
    , _state        :: V3000State
    }


type Content = V3000Content


instance showV3000Content :: Show V3000Content where
    show content
        =  "(V30000Content { atoms: "
        <> (show $ atoms content)
        <> ", bondSegments: "
        <> (show $ bondSegments content)
        <> ", state: "
        <> (show $ state content)
        <> " })"


emptyContent :: Content
emptyContent = V3000Content
    { _atoms:            empty
    , _bondSegments:     Nil
    , _state:            NotReading
    }


atoms :: Content -> List GeometryAtom
atoms (V3000Content { _atoms }) = values _atoms


atoms' :: Content -> Map Int GeometryAtom
atoms' (V3000Content { _atoms }) = _atoms


state :: Content -> V3000State
state (V3000Content { _state }) = _state


bondSegments :: Content -> List BS.BondSegment
bondSegments (V3000Content { _bondSegments }) = _bondSegments


parseV3000 :: String -> Either String Content
parseV3000 = foldl parser (Right emptyContent) <<< validLines
  where
    validLines = filter ((<) 0 <<< length) <<< lines

    parser :: Either String Content -> String -> Either String Content
    parser maybeContent line = do
       content <- maybeContent
       v3000Parser line content


v3000Parser :: String -> Content -> Either String Content
v3000Parser line content@(V3000Content { _state: ReadingAtoms })
    | includes "M  V30 END ATOM" line = Right
        (V3000Content
            { _atoms: atoms' content
            , _bondSegments: bondSegments content
            , _state: NotReading
            }
        )

    | otherwise = addAtom content line


v3000Parser line content@(V3000Content { _state: ReadingBonds })
    | includes "M  V30 END BOND" line = Right
        (V3000Content
            { _atoms: atoms' content
            , _bondSegments: bondSegments content
            , _state: NotReading
            }
        )

    | otherwise = addBond content line


v3000Parser line content@(V3000Content { _state: NotReading })
    | includes "M  V30 BEGIN ATOM" line = Right
        (V3000Content
            { _atoms: atoms' content
            , _bondSegments: bondSegments content
            , _state: ReadingAtoms
            }
        )

    | includes "M  V30 BEGIN BOND" line = Right
        (V3000Content
            { _atoms: atoms' content
            , _bondSegments: bondSegments content
            , _state: ReadingBonds
            }
        )

    | otherwise = Right content


addAtom :: Content -> String -> Either String Content
addAtom content line = do
    (Tuple id atom) <- readAtom $ validWords line
    pure (V3000Content
        { _atoms: insert id atom (atoms' content)
        , _bondSegments: bondSegments content
        , _state: state content
        }
    )


addBond :: Content -> String -> Either String Content
addBond content line = do
    newSegments <- readBond (atoms' content) $ validWords line
    pure (V3000Content
        { _atoms: atoms' content
        , _bondSegments: newSegments <> bondSegments content
        , _state: state content
        }
    )


validWords :: String -> List String
validWords = fromFoldable <<< filter ((<) 0 <<< length) <<< words


readAtom :: List String -> Either String (Tuple Int GeometryAtom)
readAtom (_:_:id:element:x:y:z:_) = do

    symbol
        <- toEither "Failed to parse element." $ chemicalSymbol element
    id' <- toEither "Failed to parse id."      $ I.fromString id
    x'  <- toEither "Failed to parse x."       $ N.fromString x
    y'  <- toEither "Failed to parse y."       $ N.fromString y
    z'  <- toEither "Failed to parse z."       $ N.fromString z

    let atom' = atom symbol (Position x' y' z') id'

    Right (Tuple id' atom')

readAtom failed = Left (show failed)


readBond
    :: Map Int GeometryAtom
    -> List String
    -> Either String (List BS.BondSegment)

readBond atoms'' (_:_:_:order:atom1Id:atom2Id:_) = do

    order'
        <- toEither "Failed to parse order." $ I.fromString order
    atom1Id'
        <- toEither "Failed to parse atom1 id." $ I.fromString atom1Id
    atom2Id'
        <- toEither "Failed to parse atom2 id." $ I.fromString atom2Id
    atom1
        <- toEither "Atom 1 not found." $ lookup atom1Id' atoms''
    atom2
        <- toEither "Atom 2 not found." $ lookup atom2Id' atoms''

    Right $ BS.bondSegments order' atom1 atom2

readBond _ failed = Left (show failed)