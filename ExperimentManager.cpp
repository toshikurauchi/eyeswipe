#include <QDateTime>
#include <QDebug>

#include "ExperimentManager.h"
#include "Timer.h"

#define GESTURE_CANCELED    "CAN"
#define CHAR_ADDED          "CHR"
#define KEY_CLICKED         "CLK"
#define CANDIDATES          "CND"
#define WORD_REMOVED        "DEL"
#define USING_DWELL         "DWL"
#define EXPECTED_SENTENCE   "EXP"
#define FIRST_LETTER        "FLT"
#define TOGGLE_GESTURE      "GES"
#define FINISH_GESTURE      "GFN"
#define START_GESTURE       "GSR"
#define FSM_HIDE_DELETE     "HDO"
#define LAST_LETTER         "LLT"
#define CANDIDATE_CHANGED   "NCD"
#define KEY_OUT             "OUT"
#define ADD_PUNCT           "PNC"
#define PAUSED              "PSD"
#define RECALIBRATED        "RCL"
#define RESTART_GESTURE     "RGS"
#define FSM_CANCEL_TYPING   "SCT"
#define FSM_SHOW_DELETE     "SDO"
#define FSM_DELETE_WORD     "SDW"
#define KEY_SELECTED        "SEL"
#define FSM_FINISHED_TYPING "SFN"
#define FSM_HIDE_CANDIDATES "SHC"
#define SPACE_ADDED         "SPC"
#define FSM_SHOW_CANDIDATES "SSC"
#define FSM_STARTED_TYPING  "SST"
#define KEYSTROKE           "STR"
#define TYPING_CHANGED      "TPC"
#define TYPED_SENTENCE      "TYP"
#define UNPAUSED            "UNP"
#define NEW_WORD            "WRD"

ExperimentManager::ExperimentManager() :
    QObject(0),
    started(false),
    training(false),
    t0(Timer::timestamp()),
    totalSessions(3),
    sessionCount(0)
{
}

ExperimentManager::~ExperimentManager()
{
    if (isValid())
    {
        closeLogFiles();
    }
}

bool ExperimentManager::isValid()
{
    return this->dataFolder.length() > 0 && this->pid.length() > 0;
}

QDir ExperimentManager::getParticipantDir()
{
    return participantDir;
}

void ExperimentManager::startExperiment()
{
    newSession();
    started = true;
    t0 = Timer::timestamp();
    pausedT0 = -1;
    pausedTime = 0;
    sessionCount++;
}

void ExperimentManager::stopExperiment()
{
    closeLogFiles();
    started = false;
}

double ExperimentManager::getTimestamp()
{
    return Timer::timestamp();
}

double ExperimentManager::sessionEllapsedTime()
{
    if (started) return Timer::timestamp() - t0 - getPausedTime();
    return 0;
}

int ExperimentManager::getCurrentSessionID()
{
    int id = 1;
    while (QDir(modeDir.absoluteFilePath(QString::fromStdString(std::to_string(id)))).exists()) id++;
    return id;
}

int ExperimentManager::getTotalSessions()
{
    return totalSessions;
}

bool ExperimentManager::ended()
{
    return sessionCount >= totalSessions;
}

bool ExperimentManager::isTraining()
{
    return this->training;
}

void ExperimentManager::setup(QString dataFolder, int sessions, QString pid, bool training)
{
    this->dataFolder = dataFolder;
    this->pid = pid;
    this->totalSessions = sessions;
    this->training = training;

    if (isValid())
    {
        QDir data(dataFolder);
        participantDir.setPath(data.absoluteFilePath(pid));
        sessionsDir.setPath(participantDir.absoluteFilePath("sessions"));
        if (training) sessionsDir.setPath(participantDir.absoluteFilePath("sessions/training"));
        modeDir.setPath(sessionsDir.absoluteFilePath("eyeswipe"));
        if (!modeDir.exists())
        {
            qDebug() << "Creating" << modeDir.path();
            modeDir.mkpath(".");
        }
    }
}

void ExperimentManager::logUnfilteredSample(QPointF sample, double timestamp)
{
    if (!isValid() || !started) return;
    unfilteredGazeLogStream << timestamp << "," << sample.x() << "," << sample.y() << "\n";
}

void ExperimentManager::logSample(QPointF sample, double timestamp)
{
    if (!isValid() || !started) return;
    gazeLogStream << timestamp << "," << sample.x() << "," << sample.y() << "\n";
}

void ExperimentManager::logFixation(QPointF fixation, double timestamp, double duration)
{
    if (!isValid() || !started) return;
    fixationLogStream << timestamp << "," << fixation.x() << "," << fixation.y() << "," << duration << "\n";
}

void ExperimentManager::logKeyPos(QString key, QPointF pos, QPointF size)
{
    if (!isValid() || !started) return;
    keyPosLogStream << Timer::timestamp() << "," << key << "," << pos.x() << "," << pos.y() << "," << size.x() << "," << size.y() << "\n";
}

void ExperimentManager::logKeySelected(QString key)
{
    logEvent(KEY_SELECTED, Timer::timestamp(), key);
}

void ExperimentManager::logKeyClicked(QString key)
{
    logEvent(KEY_CLICKED, Timer::timestamp(), key);
}

void ExperimentManager::logKeyOut(QString key)
{
    logEvent(KEY_OUT, Timer::timestamp(), key);
}

void ExperimentManager::logStartGesture(double timestamp)
{
    logEvent(START_GESTURE, timestamp);
}

void ExperimentManager::logRestartGesture(double timestamp)
{
    logEvent(RESTART_GESTURE, timestamp);
}

void ExperimentManager::logFinishGesture(double timestamp, QString selectedWord)
{
    logEvent(FINISH_GESTURE, timestamp, selectedWord);
}

void ExperimentManager::logAddPunct(QString punct)
{
    logEvent(ADD_PUNCT, Timer::timestamp(), punct);
}

void ExperimentManager::logKeystroke(QString letter)
{
    logEvent(KEYSTROKE, Timer::timestamp(), letter.toLower());
}

void ExperimentManager::logGestureCanceled(double timestamp)
{
    logEvent(GESTURE_CANCELED, timestamp);
}

void ExperimentManager::logTypingChanged(bool isTyping)
{
    logEvent(TYPING_CHANGED, Timer::timestamp(), isTyping ? "1" : "0");
}

void ExperimentManager::logFSMStartedTyping(double timestamp)
{
    logEvent(FSM_STARTED_TYPING, timestamp);
}

void ExperimentManager::logFSMFinishedTyping(double timestamp)
{
    logEvent(FSM_FINISHED_TYPING, timestamp);
}

void ExperimentManager::logFSMCancelTyping(double timestamp)
{
    logEvent(FSM_CANCEL_TYPING, timestamp);
}

void ExperimentManager::logFSMShowCandidates(double timestamp)
{
    logEvent(FSM_SHOW_CANDIDATES, timestamp);
}

void ExperimentManager::logFSMHideCandidates(double timestamp)
{
    logEvent(FSM_HIDE_CANDIDATES, timestamp);
}

void ExperimentManager::logFSMShowDeleteOptions(double timestamp)
{
    logEvent(FSM_SHOW_DELETE, timestamp);
}

void ExperimentManager::logFSMHideDeleteOptions(double timestamp)
{
    logEvent(FSM_HIDE_DELETE, timestamp);
}

void ExperimentManager::logFSMDeleteWord(double timestamp)
{
    logEvent(FSM_DELETE_WORD, timestamp);
}

void ExperimentManager::logNewWord(QString newWord)
{
    logEvent(NEW_WORD, Timer::timestamp(), newWord);
}

void ExperimentManager::logWordRemoved(QString removedWord)
{
    logEvent(WORD_REMOVED, Timer::timestamp(), removedWord);
}

void ExperimentManager::logCandidates(QStringList candidates, int idx)
{
    logEvent(CANDIDATES, Timer::timestamp(), candidates.join(",") + QString::fromStdString(":" + std::to_string(idx)));
}

void ExperimentManager::logSpaceAdded()
{
    logEvent(SPACE_ADDED, Timer::timestamp());
}

void ExperimentManager::logCharAdded(QString newChar)
{
    logEvent(CHAR_ADDED, Timer::timestamp(), newChar);
}

void ExperimentManager::logCandidateChanged(QString newCandidate)
{
    logEvent(CANDIDATE_CHANGED, Timer::timestamp(), newCandidate);
}

void ExperimentManager::logNewFirstLetters(QString newFirstLetters)
{
    logEvent(FIRST_LETTER, Timer::timestamp(), newFirstLetters);
}

void ExperimentManager::logNewLastLetters(QString newLastLetters)
{
    logEvent(LAST_LETTER, Timer::timestamp(), newLastLetters);
}

void ExperimentManager::logExpectedSentence(QString expectedSentence)
{
    logEvent(EXPECTED_SENTENCE, Timer::timestamp(), expectedSentence);
}

void ExperimentManager::logTypedSentence(QString typedSentence)
{
    logEvent(TYPED_SENTENCE, Timer::timestamp(), typedSentence);
}

void ExperimentManager::logUsingDwell(bool usingDwell)
{
    logEvent(USING_DWELL, Timer::timestamp(), usingDwell ? "1" : "0");
}

void ExperimentManager::logPaused(bool isPaused)
{
    double now = Timer::timestamp();
    if (isPaused)
    {
        pausedT0 = now;
        logEvent(PAUSED, now);
    }
    else
    {
        if (pausedT0 >= 0) pausedTime += now - pausedT0;
        pausedT0 = -1;
        logEvent(UNPAUSED, now);
    }
}

void ExperimentManager::logRecalibrated()
{
    logEvent(RECALIBRATED, Timer::timestamp());
}

void ExperimentManager::newSession()
{
    int sessionID = getCurrentSessionID();
    currentSessionDir.setPath(modeDir.absoluteFilePath(QString::fromStdString(std::to_string(sessionID))));
    qDebug() << "Creating session folder" << currentSessionDir.path();

    sessionCreations.setFileName(sessionsDir.absoluteFilePath("sessions.csv"));
    if (sessionCreations.open(QIODevice::Append))
    {
        QTextStream stream(&sessionCreations);
        stream << QDateTime::currentDateTime().toString("MM-dd-yyyy: hh:mm:ss ") << currentSessionDir.path() << "\n";
    }

    currentSessionDir.mkpath(".");
    openAndSetStream(currentSessionDir.absoluteFilePath("gaze.csv"), gazeLog, gazeLogStream);
    openAndSetStream(currentSessionDir.absoluteFilePath("raw_gaze.csv"), unfilteredGazeLog, unfilteredGazeLogStream);
    openAndSetStream(currentSessionDir.absoluteFilePath("fixations.csv"), fixationLog, fixationLogStream);
    openAndSetStream(currentSessionDir.absoluteFilePath("keys.csv"), keyPosLog, keyPosLogStream);
    openAndSetStream(currentSessionDir.absoluteFilePath("events.csv"), eventLog, eventLogStream);
}

void ExperimentManager::openAndSetStream(QString path, QFile &file, QTextStream &stream)
{
    file.setFileName(path);
    if (file.open(QIODevice::WriteOnly))
    {
        stream.setDevice(&file);
    }
}

void ExperimentManager::logEvent(QString eventID, double timestamp, QString data)
{
    if (!isValid() || !started) return;
    if (data.length() > 0)
    {
        eventLogStream << timestamp << "," << eventID << "," << data << "\n";
    }
    else
    {
        eventLogStream << timestamp << "," << eventID << "\n";
    }
}

void ExperimentManager::closeLogFiles()
{
    if (gazeLog.isOpen()) gazeLog.close();
    if (fixationLog.isOpen()) fixationLog.close();
    if (keyPosLog.isOpen()) keyPosLog.close();
    if (eventLog.isOpen()) eventLog.close();
}

double ExperimentManager::getPausedTime() {
    if (pausedT0 < 0) return pausedTime;
    return pausedTime + Timer::timestamp() - pausedT0;
}
