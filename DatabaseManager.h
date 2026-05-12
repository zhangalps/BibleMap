#ifndef DATABASEMANAGER_H
#define DATABASEMANAGER_H

#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>

class DatabaseManager : public QObject
{
    Q_OBJECT

public:
    explicit DatabaseManager(QObject *parent = nullptr);
    ~DatabaseManager();

    // Invokable from QML
    Q_INVOKABLE QVariantList getAllPlaces();
    Q_INVOKABLE QVariantList getPlacesInRegion(double minLat, double maxLat, double minLon, double maxLon, int zoomLevel);
    Q_INVOKABLE QVariantList getPlaceRefs(int placeId);
    Q_INVOKABLE QVariantList searchPlaces(const QString &keyword);
    Q_INVOKABLE QVariantList getVerses(const QString &book, int chapter);
    Q_INVOKABLE QString getBookName(const QString &shortName);
    Q_INVOKABLE QVariantList getAllBooks();
    Q_INVOKABLE int getChapterCount(const QString &book);
    Q_INVOKABLE int getVerseCount(const QString &book, int chapter);

private:
    bool initDatabases();
    QString adapterBookName(const QString &shortName);
    QSqlDatabase m_mapDb;
    QSqlDatabase m_bibleDb;
};

#endif // DATABASEMANAGER_H
