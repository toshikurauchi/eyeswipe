#ifndef EXPERIMENTMANAGER_H
#define EXPERIMENTMANAGER_H

#include <QObject>
#include <QDir>
#include <QFile>
#include <QTextStream>
#include <QPointF>

class ExperimentManager : public QObject
{
    Q_OBJECT
public:
    ExperimentManager();
    ~ExperimentManager();
    bool isValid();
    QDir getParticipantDir();
    Q_INVOKABLE void startExperiment();
    Q_INVOKABLE void stopExperiment();
    Q_INVOKABLE double getTimestamp();
    Q_INVOKABLE double sessionEllapsedTime();
    Q_INVOKABLE int getCurrentSessionID();
    Q_INVOKABLE int getTotalSessions();
    Q_INVOKABLE bool ended();
    bool isTraining();

public slots:
    void setup(QString dataFolder, int sessions, QString pid, bool training);
    void logUnfilteredSample(QPointF sample, double timestamp);
    void logSample(QPointF sample, double timestamp);
    void logFixation(QPointF fixation, double timestamp, double duration);
    void logKeyPos(QString key, QPointF pos, QPointF size);
    void logKeySelected(QString key);
    void logKeyClicked(QString key);
    void logKeyOut(QString key);
    void logStartGesture(double timestamp);
    void logRestartGesture(double timestamp);
    void logFinishGesture(double timestamp, QString selectedWord);
    void logAddPunct(QString punct);
    void logKeystroke(QString letter);
    void logGestureCanceled(double timestamp);
    void logTypingChanged(bool isTyping);
    void logFSMStartedTyping(double timestamp);
    void logFSMFinishedTyping(double timestamp);
    void logFSMCancelTyping(double timestamp);
    void logFSMShowCandidates(double timestamp);
    void logFSMHideCandidates(double timestamp);
    void logFSMShowDeleteOptions(double timestamp);
    void logFSMHideDeleteOptions(double timestamp);
    void logFSMDeleteWord(double timestamp);
    void logNewWord(QString newWord);
    void logWordRemoved(QString removedWord);
    void logCandidates(QStringList candidates, int idx);
    void logSpaceAdded();
    void logCharAdded(QString newChar);
    void logCandidateChanged(QString newCandidate);
    void logNewFirstLetters(QString newFirstLetters);
    void logNewLastLetters(QString newLastLetters);
    void logExpectedSentence(QString expectedSentence);
    void logTypedSentence(QString typedSentence);
    void logUsingDwell(bool usingDwell);
    void logPaused(bool isPaused);
    void logRecalibrated();
    void newSession();

private:
    QString dataFolder;
    QString pid;
    QDir participantDir;
    QDir sessionsDir;
    QDir modeDir;
    QDir currentSessionDir;
    QFile sessionCreations;
    QFile gazeLog;
    QTextStream gazeLogStream;
    QFile unfilteredGazeLog;
    QTextStream unfilteredGazeLogStream;
    QFile fixationLog;
    QTextStream fixationLogStream;
    QFile keyPosLog;
    QTextStream keyPosLogStream;
    QFile eventLog;
    QTextStream eventLogStream;
    bool started;
    bool training;
    double t0;
    double pausedT0;
    double pausedTime;
    int totalSessions;
    int sessionCount;

    void openAndSetStream(QString path, QFile &file, QTextStream &stream);
    void logEvent(QString eventID, double timestamp, QString data = "");
    void closeLogFiles();
    double getPausedTime();
};

#endif // EXPERIMENTMANAGER_H
