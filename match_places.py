import sqlite3
import math

def distance(lat1, lon1, lat2, lon2):
    # simple euclidean distance for mapping
    return math.sqrt((lat1-lat2)**2 + (lon1-lon2)**2)

db = sqlite3.connect('resource/map.db')
c = db.cursor()
c.execute("SELECT id, name_cn, lat, lon FROM places")
places = c.fetchall()

routes = {
    "aiji": [
        ("兰塞", 30.8010, 31.8410),
        ("疏割", 30.5500, 32.0900),
        ("伊坦", 29.9800, 32.5500),
        ("以琳", 29.1000, 33.1000),
        ("西奈山", 28.5390, 33.9750),
        ("以旬迦别", 29.5300, 34.9900),
        ("加低斯巴尼亚", 30.6400, 34.4200),
        ("尼波山", 31.7680, 35.7190),
        ("耶利哥", 31.8600, 35.4600)
    ],
    "jesus": [
        ("伯利恒", 31.7050, 35.2020),
        ("逃往埃及", 30.0444, 31.2357),
        ("拿撒勒", 32.7020, 35.3030),
        ("约旦河外伯大尼", 31.8360, 35.5460),
        ("犹大旷野", 31.8700, 35.3900),
        ("迦拿", 32.7400, 35.3300),
        ("迦百农", 32.8800, 35.5700),
        ("凯撒利亚·腓立比", 33.2400, 35.6900),
        ("耶路撒冷", 31.7780, 35.2350)
    ],
    "paul": [
        ("安提阿", 36.2020, 36.1600),
        ("以哥念", 37.8710, 32.4840),
        ("以弗所", 37.9400, 27.3400),
        ("特罗亚", 39.7500, 26.1600),
        ("腓立比", 41.0120, 24.2840),
        ("帖撒罗尼迦", 40.6400, 22.9440),
        ("雅典", 37.9830, 23.7270),
        ("哥林多", 37.9060, 22.8780),
        ("耶路撒冷", 31.7780, 35.2350),
        ("凯撒利亚", 32.5010, 34.8980),
        ("克里特岛佳澳", 34.9310, 24.8210),
        ("马耳他", 35.8840, 14.4150),
        ("叙拉古", 37.0750, 15.2860),
        ("罗马", 41.9020, 12.4960)
    ]
}

for route_name, r_places in routes.items():
    print(f"--- Route: {route_name} ---")
    for r_name, r_lat, r_lon in r_places:
        best_match = None
        best_dist = 9999
        # First try exact name match
        exact_matches = [p for p in places if r_name in p[1]]
        if exact_matches:
            best_match = exact_matches[0]
            best_dist = distance(r_lat, r_lon, best_match[2], best_match[3])
        else:
            for p in places:
                d = distance(r_lat, r_lon, p[2], p[3])
                if d < best_dist:
                    best_dist = d
                    best_match = p
        if best_dist < 1.0: # ~100km
            print(f"Matched '{r_name}' to DB '{best_match[1]}' (ID: {best_match[0]}) - dist: {best_dist:.3f}")
        else:
            print(f"NO CLOSE MATCH for '{r_name}' (Closest: {best_match[1]} at dist {best_dist:.3f})")

