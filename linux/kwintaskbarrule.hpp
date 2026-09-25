// kwintaskbarrule.hpp
// LibrePods HiiT: keeps the window out of the taskbar on KDE Plasma. On Wayland an app cannot
// ask for that itself (Qt::Tool and _NET_WM_STATE_SKIP_TASKBAR only work on X11), so the app
// adds a KWin window rule for its own app id, the same one the user could create in
// System Settings > Window Rules, and removes it again when the window should be listed.
#ifndef KWINTASKBARRULE_HPP
#define KWINTASKBARRULE_HPP

#include <QDBusConnection>
#include <QDBusMessage>
#include <QGuiApplication>
#include <QProcess>
#include <QStandardPaths>
#include <QStringList>

namespace KWinTaskbarRule
{
    inline const QString kRulesFile = QStringLiteral("kwinrulesrc");
    inline const QString kRuleGroup = QStringLiteral("librepods-hiit-skip-taskbar");

    // Plasma with the kconfig command line tools, which KWin reads the rules through
    inline bool isSupported()
    {
        return qEnvironmentVariable("XDG_CURRENT_DESKTOP").contains(QLatin1String("KDE"), Qt::CaseInsensitive)
               && !QStandardPaths::findExecutable(QStringLiteral("kwriteconfig6")).isEmpty()
               && !QStandardPaths::findExecutable(QStringLiteral("kreadconfig6")).isEmpty();
    }

    inline QString readEntry(const QString &group, const QString &key)
    {
        QProcess process;
        process.start(QStringLiteral("kreadconfig6"),
                      {"--file", kRulesFile, "--group", group, "--key", key});
        process.waitForFinished(3000);
        return QString::fromUtf8(process.readAllStandardOutput()).trimmed();
    }

    inline void writeEntry(const QString &group, const QString &key, const QString &value)
    {
        QProcess::execute(QStringLiteral("kwriteconfig6"),
                          {"--file", kRulesFile, "--group", group, "--key", key, value});
    }

    inline void deleteEntry(const QString &group, const QString &key)
    {
        QProcess::execute(QStringLiteral("kwriteconfig6"),
                          {"--file", kRulesFile, "--group", group, "--key", key, "--delete"});
    }

    // The [General] rules list is shared with the user's own rules: only our entry is touched
    inline void setListed(bool present)
    {
        QStringList rules = readEntry(QStringLiteral("General"), QStringLiteral("rules"))
                                .split(',', Qt::SkipEmptyParts);
        if (rules.contains(kRuleGroup) == present)
            return;
        if (present)
            rules.append(kRuleGroup);
        else
            rules.removeAll(kRuleGroup);
        writeEntry(QStringLiteral("General"), QStringLiteral("rules"), rules.join(','));
        writeEntry(QStringLiteral("General"), QStringLiteral("count"), QString::number(rules.size()));
    }

    inline void reconfigureKWin()
    {
        QDBusConnection::sessionBus().call(QDBusMessage::createMethodCall(
            QStringLiteral("org.kde.KWin"), QStringLiteral("/KWin"),
            QStringLiteral("org.kde.KWin"), QStringLiteral("reconfigure")));
    }

    // hide = true adds the rule (window only in the tray), false removes it
    inline void apply(bool hide)
    {
        if (!isSupported())
            return;

        const bool present = readEntry(kRuleGroup, QStringLiteral("skiptaskbar")) == QLatin1String("true");
        if (present == hide)
            return;

        const QStringList keys = {"Description", "wmclass", "wmclassmatch", "skiptaskbar", "skiptaskbarrule"};
        if (hide)
        {
            writeEntry(kRuleGroup, QStringLiteral("Description"), QStringLiteral("LibrePods HiiT: tray only"));
            writeEntry(kRuleGroup, QStringLiteral("wmclass"), QGuiApplication::desktopFileName());
            writeEntry(kRuleGroup, QStringLiteral("wmclassmatch"), QStringLiteral("1")); // exact match
            writeEntry(kRuleGroup, QStringLiteral("skiptaskbar"), QStringLiteral("true"));
            writeEntry(kRuleGroup, QStringLiteral("skiptaskbarrule"), QStringLiteral("2")); // force
        }
        else
        {
            for (const QString &key : keys)
                deleteEntry(kRuleGroup, key);
        }
        setListed(hide);
        reconfigureKWin();
    }
}

#endif // KWINTASKBARRULE_HPP
