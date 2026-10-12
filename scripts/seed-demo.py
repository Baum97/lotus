#!/usr/bin/env python3
"""Legt Demo-Profile in Stuttgart und Ulm an – NUR für die lokale Entwicklung.

Fotos sind neutrale Platzhalter (Farbverlauf + Initial), keine echten Menschen.

    python3 scripts/seed-demo.py                      # nutzt `supabase status`
    python3 scripts/seed-demo.py --like-me du@mail.de # Demo-Personen liken dieses Konto

Benötigt: Pillow (pip install pillow).
"""

import argparse
import io
import json
import os
import subprocess
import sys
import urllib.error
import urllib.request

from PIL import Image, ImageDraw, ImageFont

STUTTGART = (9.18, 48.78)
ULM = (9.99, 48.40)

# name, gender, interested_in, age, city, intention, intention_public, bio, prompts
PEOPLE = [
    ("Jonas", "man", ["woman"], 31, "Stuttgart", "relationship", True,
     "Ingenieur, Hobbykoch, sonntags am Bärensee.",
     [(1, "Brötchen holen, lange frühstücken, dann raus in den Wald."), (7, "… auf dem Markt am Schillerplatz anfangen.")]),
    ("Lukas", "man", ["woman"], 29, "Stuttgart", "open_to_relationship", True,
     "Lehrer und Kletterer. Suche jemanden zum Lachen.",
     [(3, "Bouldern, Brettspiele und warum Maultaschen unterschätzt sind."), (9, "Pünktlich sein. Ich arbeite dran.")]),
    ("Elias", "man", ["woman", "diverse"], 34, "Esslingen", "relationship", False,
     "Musiker, Altbauwohnung, zu viele Pflanzen.",
     [(6, "Eine neue Platte auflegen und die Hülle lesen."), (10, "Ehrlichkeit, auch wenn sie unbequem ist.")]),
    ("Felix", "man", ["woman"], 27, "Stuttgart", "unsure", True,
     "Medizinstudent, Läufer, Kaffeesnob.",
     [(4, "Die Weinberge in Uhlbach zum Sonnenuntergang."), (2, "… ich ihnen meine Lieblingsorte zeigen will.")]),
    ("Paul", "man", ["woman"], 38, "Ludwigsburg", "relationship", True,
     "Papa einer Tochter, liebt Schlossgärten und Sauerteig.",
     [(5, "Gemeinsam Alltag schön machen."), (8, "Ich tanze Salsa. Schlecht, aber mit Begeisterung.")]),
    ("Moritz", "man", ["woman"], 30, "Ulm", "relationship", True,
     "Ulmer durch und durch, Donau-Schwimmer.",
     [(4, "Das Fischerviertel, früh morgens."), (1, "Radtour an der Donau, Biergarten, fertig.")]),
    ("David", "man", ["man"], 33, "Stuttgart", "relationship", True,
     "Architekt, liebt Theater und lange Spaziergänge.",
     [(3, "Gebäude, die niemand beachtet."), (5, "Vertrauen und gemeinsame Abenteuer.")]),
    ("Sara", "woman", ["man"], 28, "Stuttgart", "relationship", True,
     "Grafikdesignerin, Katzenmensch.",
     [(6, "Frische Blumen auf dem Küchentisch."), (7, "… mit einem Spaziergang anfangen, nicht mit einem Interview.")]),
    ("Lea", "woman", ["woman"], 26, "Ulm", "open_to_relationship", True,
     "Pflegerin, Festival-Fan, Hundeliebhaberin.",
     [(2, "… ich nach dem Date direkt meiner besten Freundin schreibe."), (4, "Der Glacis-Park im Herbst.")]),
    ("Alex", "diverse", ["woman", "man", "diverse"], 29, "Ulm", "unsure", True,
     "Softwareentwickler:in, Hobby-Imker:in.",
     [(3, "Bienen. Wirklich, frag mich nicht, sonst hörst du nie wieder auf."), (9, "Kurze Antworten.")]),
    ("Noah", "man", ["woman"], 32, "Neu-Ulm", "relationship", False,
     "Physiotherapeut, Wochenend-Wanderer.",
     [(1, "Schwäbische Alb, Rucksack, Vesper."), (10, "Respekt im Streit.")]),
    ("Ben", "man", ["woman"], 35, "Stuttgart", "open_to_relationship", True,
     "Koch, Weinliebhaber, Heimwerker.",
     [(7, "… in einer Besenwirtschaft enden."), (6, "Wenn der Sauerteig aufgeht.")]),
]

PALETTE = [((243, 221, 226), (184, 103, 122)), ((225, 235, 226), (126, 156, 131)),
           ((241, 234, 225), (176, 140, 110)), ((226, 230, 243), (110, 125, 180))]


def supabase_status():
    repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out = subprocess.run(["npx", "-y", "supabase@latest", "status", "-o", "json"],
                         capture_output=True, text=True, check=True, cwd=repo).stdout
    data = json.loads(out[out.index("{"):])
    return data["API_URL"], data["SERVICE_ROLE_KEY"]


class Api:
    def __init__(self, url, key):
        self.url, self.key = url, key

    def request(self, method, path, body=None, content_type="application/json", extra=None):
        data = body if isinstance(body, (bytes, type(None))) else json.dumps(body).encode()
        headers = {"apikey": self.key, "Authorization": f"Bearer {self.key}", "Content-Type": content_type,
                   "Prefer": "return=representation"}
        headers.update(extra or {})
        req = urllib.request.Request(self.url + path, data=data, method=method, headers=headers)
        try:
            with urllib.request.urlopen(req) as resp:
                raw = resp.read()
                return json.loads(raw) if raw else None
        except urllib.error.HTTPError as e:
            raise SystemExit(f"{method} {path} → {e.code}: {e.read().decode()}")


def placeholder_photo(name, index):
    top, bottom = PALETTE[(len(name) + index) % len(PALETTE)]
    img = Image.new("RGB", (800, 1000))
    draw = ImageDraw.Draw(img)
    for y in range(1000):
        t = y / 999
        draw.line([(0, y), (800, y)], fill=tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)))
    try:
        font = ImageFont.truetype("DejaVuSans-Bold.ttf", 360)
    except OSError:
        font = ImageFont.load_default()
    draw.text((400, 470), name[0], fill=(255, 255, 255), font=font, anchor="mm")
    draw.text((400, 900), f"Demo-Foto {index + 1}", fill=(255, 255, 255), anchor="mm")
    buf = io.BytesIO()
    img.save(buf, "JPEG", quality=85)
    return buf.getvalue()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--url")
    parser.add_argument("--service-key")
    parser.add_argument("--like-me", help="E-Mail eines Kontos, das von einigen Demo-Personen geliked wird")
    args = parser.parse_args()
    url, key = (args.url, args.service_key) if args.url else supabase_status()
    if "127.0.0.1" not in url and "localhost" not in url:
        sys.exit("Abbruch: Demo-Daten nur in die lokale Datenbank einspielen.")
    api = Api(url, key)

    users = api.request("GET", "/auth/v1/admin/users?per_page=1000")["users"]
    existing = {u["email"]: u["id"] for u in users}
    ids = {}
    for i, (name, gender, interested, age, city, intention, public, bio, prompts) in enumerate(PEOPLE):
        email = f"{name.lower()}@demo.lotus.local"
        if email in existing:
            ids[name] = existing[email]
            continue
        uid = api.request("POST", "/auth/v1/admin/users", {"email": email, "email_confirm": True})["id"]
        ids[name] = uid
        lon, lat = ULM if city in ("Ulm", "Neu-Ulm") else STUTTGART
        lon, lat = lon + (i % 3) * 0.02, lat + (i % 4) * 0.015
        api.request("POST", "/rest/v1/profiles", {
            "id": uid, "display_name": name, "birthdate": f"{2026 - age}-03-15", "gender": gender,
            "bio": bio, "city": city})
        api.request("POST", "/rest/v1/match_preferences", {
            "user_id": uid, "interested_in": interested, "intention": intention, "intention_public": public,
            "age_min": 22, "age_max": 45, "max_distance_km": 60})
        api.request("POST", "/rest/v1/profile_locations", {"user_id": uid, "location": f"SRID=4326;POINT({lon} {lat})"})
        for p in range(2):
            path = f"{uid}/{p}.jpg"
            api.request("POST", f"/storage/v1/object/photos/{path}", placeholder_photo(name, p), "image/jpeg")
            api.request("POST", "/rest/v1/photos", {"user_id": uid, "storage_path": path, "position": p})
        for pos, (prompt_id, answer) in enumerate(prompts):
            api.request("POST", "/rest/v1/prompt_answers",
                        {"user_id": uid, "prompt_id": prompt_id, "answer": answer, "position": pos})
        # Demo-Personen sind verifiziert, damit man direkt chatten kann
        api.request("PATCH", f"/rest/v1/profiles?id=eq.{uid}", {"verified_at": "2026-10-01T12:00:00Z"})
        print(f"✓ {name} ({city})")

    if args.like_me:
        me = existing.get(args.like_me) or next(
            (u["id"] for u in api.request("GET", "/auth/v1/admin/users?per_page=1000")["users"]
             if u["email"] == args.like_me), None)
        if not me:
            sys.exit(f"Konto {args.like_me} nicht gefunden – erst in der App anmelden.")
        photo = api.request("GET", f"/rest/v1/photos?user_id=eq.{me}&select=id&limit=1")
        target = {"target_type": "photo", "target_id": photo[0]["id"]} if photo else {}
        comments = {"Jonas": "Dein Lächeln auf dem Foto ist ansteckend!", "Moritz": None, "Ben": "Kochen wir mal zusammen?"}
        for name, comment in comments.items():
            api.request("POST", "/rest/v1/likes?on_conflict=from_user,to_user",
                        {"from_user": ids[name], "to_user": me, "comment": comment, **target},
                        extra={"Prefer": "resolution=ignore-duplicates"})
        print(f"✓ {', '.join(comments)} liken {args.like_me}")


if __name__ == "__main__":
    main()
