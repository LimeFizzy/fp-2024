{-# LANGUAGE InstanceSigs #-}

module Lib2
  ( Query (..),
    GrapeType (..),
    WineType (..),
    Unit (..),
    BarrelType (..),
    Duration (..),
    parseQuery,
    State (..),
    emptyState,
    stateTransition,
  )
where

import Text.Read (readMaybe)

-- | Data types for Queries and State
data Query
  = Harvest GrapeType Int Unit
  | Ferment GrapeType Duration
  | Age WineType Duration BarrelType
  | Bottle WineType Int Unit
  | Sell WineType Int Double
  | View
  deriving (Eq, Show)

data GrapeType = CabernetSauvignon | Merlot | PinotNoir | Chardonnay
  deriving (Eq, Show)

data WineType = RedWine | WhiteWine | RoseWine
  deriving (Eq, Show)

data Unit = Kg | L | Bottles
  deriving (Eq, Show)

data BarrelType = Oak | Steel | Clay
  deriving (Eq, Show)

data Duration = Days Int | Months Int
  deriving (Eq, Show)

data State = State {processes :: [Query]} deriving (Eq, Show)

-- | Parse grape type
-- <grape_type> ::= "CabernetSauvignon" | "Merlot" | "PinotNoir" | "Chardonnay"
parseGrapeType :: String -> Maybe GrapeType
parseGrapeType "CabernetSauvignon" = Just CabernetSauvignon
parseGrapeType "Merlot" = Just Merlot
parseGrapeType "PinotNoir" = Just PinotNoir
parseGrapeType "Chardonnay" = Just Chardonnay
parseGrapeType _ = Nothing

-- | Parse wine type
-- <wine_type> ::= "RedWine" | "WhiteWine" | "RoseWine"
parseWineType :: String -> Maybe WineType
parseWineType "RedWine" = Just RedWine
parseWineType "WhiteWine" = Just WhiteWine
parseWineType "RoseWine" = Just RoseWine
parseWineType _ = Nothing

-- | Parse unit
-- <unit> ::= "kg" | "L" | "bottles"
parseUnit :: String -> Maybe Unit
parseUnit "kg" = Just Kg
parseUnit "L" = Just L
parseUnit "bottles" = Just Bottles
parseUnit _ = Nothing

-- | Parse barrel type
-- <barrel_type> ::= "Oak" | "Steel" | "Clay"
parseBarrelType :: String -> Maybe BarrelType
parseBarrelType "Oak" = Just Oak
parseBarrelType "Steel" = Just Steel
parseBarrelType "Clay" = Just Clay
parseBarrelType _ = Nothing

-- | Parse duration
-- <duration> ::= <number> "days" | <number> "months"
parseDuration :: String -> Maybe Duration
parseDuration s = case words s of
  [n, "days"] -> Days <$> readMaybe n
  [n, "months"] -> Months <$> readMaybe n
  _ -> Nothing

-- | Parses user's input.
parseQuery :: String -> Either String Query
parseQuery input =
  case words (filter (`notElem` "(),") input) of
    -- <harvest> ::= "harvest" "(" <grape_type> "," <quantity> ")"
    ("harvest" : g : n : u : _) ->
      case (parseGrapeType g, readMaybe n :: Maybe Int, parseUnit u) of
        (Just grape, Just quantity, Just unit) -> Right (Harvest grape quantity unit)
        _ -> Left "Failed to parse harvest"
    -- <ferment> ::= "ferment" "(" <grape_type> "," <duration> ")"
    ("ferment" : g : n : d : _) ->
      case (parseGrapeType g, parseDuration (n ++ " " ++ d)) of
        (Just grape, Just duration) -> Right (Ferment grape duration)
        _ -> Left "Failed to parse ferment"
    -- <age> ::= "age" "(" <wine_type> "," <duration> "," <barrel_type> ")"
    ("age" : w : n : d : b : _) ->
      case (parseWineType w, parseDuration (n ++ " " ++ d), parseBarrelType b) of
        (Just wine, Just duration, Just barrel) -> Right (Age wine duration barrel)
        _ -> Left "Failed to parse age"
    -- <bottle> ::= "bottle" "(" <wine_type> "," <quantity> ")"
    ("bottle" : w : n : u : _) ->
      case (parseWineType w, readMaybe n :: Maybe Int, parseUnit u) of
        (Just wine, Just quantity, Just unit) -> Right (Bottle wine quantity unit)
        _ -> Left "Failed to parse bottle"
    -- <sell> ::= "sell" "(" <wine_type> "," <quantity> "," <price> ")"
    ("sell" : w : n : p : _) ->
      case (parseWineType w, readMaybe n :: Maybe Int, readMaybe p :: Maybe Double) of
        (Just wine, Just quantity, Just price) -> Right (Sell wine quantity price)
        _ -> Left "Failed to parse sell"
    -- <view> ::= "view"
    ("view" : _) -> Right View
    _ -> Left "Unknown command"

-- | Initial program state.
emptyState :: State
emptyState = State {processes = []}

-- | Transition the state with a new query.
stateTransition :: State -> Query -> Either String (Maybe String, State)
stateTransition st query = case query of
  View -> Right (Just (show st), st)
  _ -> Right (Just (show query), st {processes = query : processes st})
