import os
import requests
from datetime import datetime

# ---------------------------
# CONFIG
# ---------------------------
repo_path = r"C:\Users\jackl\Git_Repo"  # <-- Local repo folder
file_path = os.path.join(repo_path, "daily_sports.md")
LEAGUES = ["NBA", "NFL", "MLB"]

# Ensure the repo folder exists
os.makedirs(repo_path, exist_ok=True)

# ---------------------------
# FUNCTION TO GET GAME INFO
# ---------------------------
def get_game(league):
    api_url = "https://www.thesportsdb.com/api/v1/json/1/eventsday.php"
    params = {
        "d": datetime.now().strftime("%Y-%m-%d"),
        "l": league
    }

    response = requests.get(api_url, params=params)
    if response.status_code != 200 or not response.text:
        return None

    try:
        data = response.json()
    except ValueError:
        return None

    if data.get("events"):
        event = data["events"][0]
        home_team = event.get("strHomeTeam", "TBD")
        away_team = event.get("strAwayTeam", "TBD")
        home_score = event.get("intHomeScore") or 0
        away_score = event.get("intAwayScore") or 0
        date = event.get("dateEvent", datetime.now().strftime("%Y-%m-%d"))
        return f"### {league} Game on {date}\n{home_team} {home_score} - {away_score} {away_team}\n\n"

    return None

# ---------------------------
# FETCH GAMES AND WRITE TO FILE
# ---------------------------
with open(file_path, "a") as f:  # Append daily updates
    for league in LEAGUES:
        game_info = get_game(league)
        if game_info:
            f.write(game_info)

# ---------------------------
# GIT COMMIT AND PUSH
# ---------------------------
os.chdir(repo_path)
os.system(f'git add "{file_path}"')
commit_message = f"Add daily sports update for {datetime.now().strftime("%Y-%m-%d")}"
os.system(f'git commit -m "{commit_message}"')
os.system('git push origin main')
