import sqlite3
db = sqlite3.connect('resource/map.db')
c = db.cursor()
queries = ["腓立比", "疏割", "以琳", "逃", "埃及", "旷野", "西奈", "尼波", "红海"]
for q in queries:
    c.execute(f"SELECT id, name_cn, lat, lon FROM places WHERE name_cn LIKE '%{q}%'")
    res = c.fetchall()
    print(f"--- Query: {q} ---")
    for r in res:
        print(f"ID: {r[0]}, Name: {r[1]}, Lat: {r[2]}, Lon: {r[3]}")
