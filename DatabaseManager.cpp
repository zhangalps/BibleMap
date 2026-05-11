#include "DatabaseManager.h"
#include <QCoreApplication>
#include <QDir>
#include <QDebug>
#include <cmath>
#include <QStandardPaths>
#include <QFile>
#include <QSet>
#include <QRegularExpression>


DatabaseManager::DatabaseManager(QObject *parent)
    : QObject(parent)
{
    initDatabases();
}

DatabaseManager::~DatabaseManager()
{
    if (m_mapDb.isOpen()) m_mapDb.close();
    if (m_bibleDb.isOpen()) m_bibleDb.close();
}

bool DatabaseManager::initDatabases()
{
    QString appDataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir dir(appDataPath);
    if (!dir.exists()) {
        dir.mkpath(".");
    }

    QString mapDbPath = appDataPath + "/map.db";
    QString bibleDbPath = appDataPath + "/bible.db";

    // Copy map.db from resources if it doesn't exist
    if (!QFile::exists(mapDbPath)) {
        QFile mapResource(":/resource/map.db");
        if (mapResource.exists()) {
            mapResource.copy(mapDbPath);
            QFile::setPermissions(mapDbPath, QFile::ReadOwner | QFile::WriteOwner | QFile::ReadUser | QFile::WriteUser);
        } else {
            qWarning() << "map.db not found in resources!";
        }
    }

    // Copy bible.db from resources if it doesn't exist
    if (!QFile::exists(bibleDbPath)) {
        QFile bibleResource(":/resource/bible.db");
        if (bibleResource.exists()) {
            bibleResource.copy(bibleDbPath);
            QFile::setPermissions(bibleDbPath, QFile::ReadOwner | QFile::WriteOwner | QFile::ReadUser | QFile::WriteUser);
        } else {
            qWarning() << "bible.db not found in resources!";
        }
    }

    // Using distinct connection names
    m_mapDb = QSqlDatabase::addDatabase("QSQLITE", "map_connection");
    m_mapDb.setDatabaseName(mapDbPath);
    if (!m_mapDb.open()) {
        qWarning() << "Failed to open map.db:" << m_mapDb.lastError().text() << "at" << mapDbPath;
        return false;
    }

    m_bibleDb = QSqlDatabase::addDatabase("QSQLITE", "bible_connection");
    m_bibleDb.setDatabaseName(bibleDbPath);
    if (!m_bibleDb.open()) {
        qWarning() << "Failed to open bible.db:" << m_bibleDb.lastError().text() << "at" << bibleDbPath;
        return false;
    }

    return true;
}

QVariantList DatabaseManager::getAllPlaces()
{
    QVariantList list;
    if (!m_mapDb.isOpen()) return list;

    QSet<QString> seenNames;
    // Regex to match trailing numbers optionally preceded by whitespace
    QRegularExpression regex("\\s*\\d+$");

    // We will query ordered by lat, lon so identical coords are adjacent
    QSqlQuery query(m_mapDb);
    query.prepare("SELECT id, name_cn, lat, lon, type FROM places ORDER BY lat, lon");

    double lastLat = -999.0;
    double lastLon = -999.0;
    int currentOverlap = 0;

    if (query.exec()) {
        while (query.next()) {
            QString rawName = query.value(1).toString();
            QString baseName = rawName;
            baseName.remove(regex); // Remove trailing numbers
            baseName = baseName.trimmed();

            if (seenNames.contains(baseName)) {
                continue; // Skip duplicates
            }
            seenNames.insert(baseName);

            double lat = query.value(2).toDouble();
            double lon = query.value(3).toDouble();

            // If within 0.01 degrees (~1km), consider it overlapping
            if (std::abs(lat - lastLat) < 0.01 && std::abs(lon - lastLon) < 0.01) {
                currentOverlap++;
            } else {
                currentOverlap = 0;
                lastLat = lat;
                lastLon = lon;
            }

            QVariantMap map;
            map["id"] = query.value(0).toInt();
            map["name_cn"] = baseName;
            map["lat"] = lat;
            map["lon"] = lon;
            map["type"] = query.value(4).toString();
            map["overlapIndex"] = currentOverlap;
            list.append(map);
        }
    } else {
        qWarning() << "getAllPlaces error:" << query.lastError().text();
    }
    return list;
}

QVariantList DatabaseManager::getPlacesInRegion(double minLat, double maxLat, double minLon, double maxLon, int zoomLevel)
{
    QVariantList list;
    if (!m_mapDb.isOpen()) return list;

    // Based on zoom level, limit the number of places to avoid clutter
    int limit = 20;
    if (zoomLevel > 14) limit = 1000;
    else if (zoomLevel > 11) limit = 500;
    else if (zoomLevel > 8) limit = 200;
    else if (zoomLevel > 5) limit = 100;

    QSqlQuery query(m_mapDb);
    query.prepare("SELECT id, name_cn, lat, lon, type FROM places WHERE lat BETWEEN ? AND ? AND lon BETWEEN ? AND ? LIMIT ?");
    query.addBindValue(minLat);
    query.addBindValue(maxLat);
    query.addBindValue(minLon);
    query.addBindValue(maxLon);
    query.addBindValue(limit);

    if (query.exec()) {
        while (query.next()) {
            QVariantMap map;
            map["id"] = query.value(0).toInt();
            map["name_cn"] = query.value(1).toString();
            map["lat"] = query.value(2).toDouble();
            map["lon"] = query.value(3).toDouble();
            map["type"] = query.value(4).toString();
            list.append(map);
        }
    } else {
        qWarning() << "getPlacesInRegion error:" << query.lastError().text();
    }
    return list;
}

QVariantList DatabaseManager::getPlaceRefs(int placeId)
{
    QVariantList list;
    if (!m_mapDb.isOpen() || !m_bibleDb.isOpen()) return list;

    QSqlQuery query(m_mapDb);
    query.prepare("SELECT book, chapter, verse FROM place_refs WHERE place_id = ? ORDER BY book, chapter, verse");
    query.addBindValue(placeId);

    if (query.exec()) {
        while (query.next()) {
            QVariantMap map;
            QString book = query.value(0).toString();
            book = adapterBookName(book);
            int chapter = query.value(1).toInt();
            int verse = query.value(2).toInt();
            
            map["book"] = book;
            map["chapter"] = chapter;
            map["verse"] = verse;

            // Query verse content from bibleDb
            QSqlQuery bQuery(m_bibleDb);
            bQuery.prepare("SELECT content FROM verses WHERE book_id = (SELECT id FROM books WHERE short_name = ? OR name_cn = ? LIMIT 1) AND chapter = ? AND verse = ?");
            bQuery.addBindValue(book);
            bQuery.addBindValue(book);
            bQuery.addBindValue(chapter);
            bQuery.addBindValue(verse);
            if (bQuery.exec() && bQuery.next()) {
                map["content"] = bQuery.value(0).toString();
            } else {
                map["content"] = "";
            }

            list.append(map);
        }
    } else {
        qWarning() << "getPlaceRefs error:" << query.lastError().text();
    }
    return list;
}

QVariantList DatabaseManager::searchPlaces(const QString &keyword)
{
    QVariantList list;
    if (!m_mapDb.isOpen() || keyword.trimmed().isEmpty()) return list;

    QSqlQuery query(m_mapDb);
    query.prepare("SELECT id, name_cn, lat, lon, type FROM places WHERE name_cn LIKE ? LIMIT 20");
    query.addBindValue("%" + keyword.trimmed() + "%");

    if (query.exec()) {
        while (query.next()) {
            QVariantMap map;
            map["id"] = query.value(0).toInt();
            map["name_cn"] = query.value(1).toString();
            map["lat"] = query.value(2).toDouble();
            map["lon"] = query.value(3).toDouble();
            map["type"] = query.value(4).toString();
            list.append(map);
        }
    }
    return list;
}

QVariantList DatabaseManager::getVerses(const QString &book, int chapter)
{
    QVariantList list;
    if (!m_bibleDb.isOpen()) return list;

    // First, find the book_id
    QSqlQuery bookQuery(m_bibleDb);
    bookQuery.prepare("SELECT id FROM books WHERE short_name = ? OR name_cn = ?");
    bookQuery.addBindValue(book);
    bookQuery.addBindValue(book);
    int bookId = -1;
    if (bookQuery.exec() && bookQuery.next()) {
        bookId = bookQuery.value(0).toInt();
    } else {
        qWarning() << "Could not find book:" << book;
        return list;
    }

    QSqlQuery query(m_bibleDb);
    query.prepare("SELECT verse, content FROM verses WHERE book_id = ? AND chapter = ? ORDER BY verse ASC");
    query.addBindValue(bookId);
    query.addBindValue(chapter);

    if (query.exec()) {
        while (query.next()) {
            QVariantMap map;
            map["verse"] = query.value(0).toInt();
            map["content"] = query.value(1).toString();
            list.append(map);
        }
    } else {
        qWarning() << "getVerses error:" << query.lastError().text();
    }
    return list;
}

QString DatabaseManager::getBookName(const QString &shortName)
{
    if (!m_bibleDb.isOpen()) return shortName;
    QSqlQuery query(m_bibleDb);
    QString lowName = adapterBookName(shortName);

    query.prepare("SELECT name_cn FROM books WHERE short_name = ?");
    query.addBindValue(lowName);
    if (query.exec() && query.next()) {
        return query.value(0).toString();
    }
    return shortName;
}

QString DatabaseManager::adapterBookName(const QString &shortName)
{
    QString lowName = shortName.toLower();
    quint8 replaceIndex = 0;
    if (lowName[0].isNumber() && lowName.size() > 1) {
        replaceIndex = 1;
    }
    lowName[replaceIndex] = lowName[replaceIndex].toUpper();
    if (lowName == "Ezk" || lowName == "Ezek") {
        lowName = "Eze";
    }
    return lowName;
}
