#! /bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Do not change code above this line. Use the PSQL variable above to query your database.

# Clear existing records
$PSQL "TRUNCATE TABLE games, teams RESTART IDENTITY;" > /dev/null || exit 1

# Read the games.csv file
while IFS=',' read -r YEAR ROUND WINNER OPPONENT WINNER_GOALS OPPONENT_GOALS || [[ -n "$YEAR" ]]
do
  # Skip the CSV header and empty lines
  [[ "$YEAR" == "year" ]] && continue
  [[ -z "$YEAR" ]] && continue

  # Insert unique teams, then insert the game
  $PSQL "
    INSERT INTO teams (name)
    VALUES ('$WINNER'), ('$OPPONENT')
    ON CONFLICT (name) DO NOTHING;

    INSERT INTO games
      (year, round, winner_id, opponent_id, winner_goals, opponent_goals)
    SELECT
      $YEAR, '$ROUND', winners.team_id, opponents.team_id,
      $WINNER_GOALS, $OPPONENT_GOALS
    FROM teams AS winners
    CROSS JOIN teams AS opponents
    WHERE winners.name = '$WINNER'
      AND opponents.name = '$OPPONENT';
  " > /dev/null || exit 1
done < games.csv

