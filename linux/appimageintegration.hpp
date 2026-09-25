// appimageintegration.hpp
// LibrePods HiiT: an AppImage is a single file the user runs from anywhere, with no install
// step. On Wayland the window and tray icons come from the .desktop file named after the app
// id, and the app menu only lists installed .desktop files, so on each start from an AppImage
// the app writes (or refreshes) its own entry and icon under ~/.local/share, pointing at the
// AppImage file. An entry left by a regular install (Exec not pointing at an AppImage) is
// never touched.
#ifndef APPIMAGEINTEGRATION_HPP
#define APPIMAGEINTEGRATION_HPP

#include <QDir>
#include <QFile>
#include <QGuiApplication>
#include <QProcess>
#include <QRegularExpression>
#include <QStandardPaths>

namespace AppImageIntegration
{
    // Path of the .AppImage file when running from one, empty otherwise
    inline QString appImagePath() { return qEnvironmentVariable("APPIMAGE"); }

    inline QString quoted(const QString &path)
    {
        return path.contains(' ') ? '"' + path + '"' : path;
    }

    inline void integrate()
    {
        const QString appImage = appImagePath();
        if (appImage.isEmpty())
            return;

        const QString dataDir = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation);
        const QString desktopPath = dataDir + "/applications/" + QGuiApplication::desktopFileName() + ".desktop";

        QFile existing(desktopPath);
        if (existing.open(QIODevice::ReadOnly | QIODevice::Text))
        {
            const QString content = QString::fromUtf8(existing.readAll());
            existing.close();
            const bool fromAppImage = content.contains(QLatin1String(".AppImage"), Qt::CaseInsensitive);
            if (!fromAppImage || content.contains("Exec=" + quoted(appImage) + '\n'))
                return; // a regular install, or already pointing here
        }

        // The icon and the entry are shipped inside the AppImage (APPDIR)
        const QString appDir = qEnvironmentVariable("APPDIR");
        const QString iconDir = dataDir + "/icons/hicolor/scalable/apps";
        QDir().mkpath(iconDir);
        QFile::remove(iconDir + "/librepods.svg");
        QFile::copy(appDir + "/usr/share/icons/hicolor/scalable/apps/librepods.svg", iconDir + "/librepods.svg");

        QFile source(appDir + "/usr/share/applications/" + QGuiApplication::desktopFileName() + ".desktop");
        if (!source.open(QIODevice::ReadOnly | QIODevice::Text))
            return;
        QString entry = QString::fromUtf8(source.readAll());
        source.close();
        entry.replace(QRegularExpression("^Exec=.*$", QRegularExpression::MultilineOption),
                      "Exec=" + quoted(appImage));
        entry.replace(QRegularExpression("^TryExec=.*\\n", QRegularExpression::MultilineOption), QString());

        QDir().mkpath(dataDir + "/applications");
        QFile target(desktopPath);
        if (!target.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate))
            return;
        target.write(entry.toUtf8());
        target.close();

        // Let the desktop pick the new entry up (KDE caches them; others watch the folder)
        if (!QStandardPaths::findExecutable("kbuildsycoca6").isEmpty())
            QProcess::startDetached("kbuildsycoca6", {});
        else if (!QStandardPaths::findExecutable("update-desktop-database").isEmpty())
            QProcess::startDetached("update-desktop-database", {dataDir + "/applications"});
    }
}

#endif // APPIMAGEINTEGRATION_HPP
