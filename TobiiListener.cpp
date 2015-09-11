/*
 * This code is based on MinimalGazeDataStream.c provided in the Tobii SDK.
 * I couldn't find the documentation for the C++ API (and I only found C++11 code), so I used the C API.
 */

#include <QDebug>
#include <cassert>
#include <math.h>

#include "TobiiListener.h"
#include "Timer.h"

#ifdef Q_OS_WIN
#include "eyex/EyeX.h"

#pragma comment (lib, "Tobii.EyeX.Client.lib")

// Function declarations
void initialize();
void release();
bool InitializeGlobalInteractorSnapshot(TX_CONTEXTHANDLE hContext);
void TX_CALLCONVENTION OnSnapshotCommitted(TX_CONSTHANDLE hAsyncData, TX_USERPARAM param);
void TX_CALLCONVENTION OnEngineConnectionStateChanged(TX_CONNECTIONSTATE connectionState, TX_USERPARAM userParam);
void OnGazeDataEvent(TX_HANDLE hGazeDataBehavior);
void OnFixationDataEvent(TX_HANDLE hFixationDataBehavior);
void TX_CALLCONVENTION HandleEvent(TX_CONSTHANDLE hAsyncData, TX_USERPARAM userParam);

// Decide whether to use fixations or raw gaze samples
static const bool USE_FIXATIONS = false;

// ID of the global interactor that provides our data stream; must be unique within the application.
static TX_CONSTSTRING InteractorId = "EyeSwipeInteractor";

// global variables
static TX_HANDLE g_hGlobalInteractorSnapshot = TX_EMPTY_HANDLE;
static TX_CONTEXTHANDLE hContext = TX_EMPTY_HANDLE;
static QList<TobiiListener *> instances;
static QList<QPointF> fixationData;

// We need this because OnGazeDataEvent occurs in a different thread and onGaze has to be run on the main thread
GazeEmitter *emitter;

TobiiListener::TobiiListener(QObject *root, bool controlling) :
    QObject(root), controlling(controlling)
{
    if (instances.size() == 0)
    {
        emitter = new GazeEmitter(root);
        if (controlling) initialize();
    }
    connect(emitter, SIGNAL(newGaze(SamplePoint)), this, SLOT(onGaze(SamplePoint)));
    instances.append(this);
}

TobiiListener::~TobiiListener()
{
    instances.removeAll(this);
    if (instances.size() == 0 && controlling) release();
    delete emitter;
}

void TobiiListener::setControlling(bool controlling)
{
    this->controlling = controlling;
}

void TobiiListener::controlToggled(bool notControlling)
{
    controlling = !notControlling;
    if (controlling)
    {
        initialize();
    }
    else
    {
        release();
    }
}

void TobiiListener::onGaze(SamplePoint gaze)
{
    if (controlling)
    {
        emit newGaze(gaze);
    }
}

void initialize()
{
    hContext = TX_EMPTY_HANDLE;
    TX_TICKET hConnectionStateChangedTicket = TX_INVALID_TICKET;
    TX_TICKET hEventHandlerTicket = TX_INVALID_TICKET;
    bool success;

    // initialize and enable the context that is our link to the EyeX Engine.
    success = txInitializeEyeX(TX_EYEXCOMPONENTOVERRIDEFLAG_NONE, nullptr, nullptr, nullptr, nullptr) == TX_RESULT_OK;
    success &= txCreateContext(&hContext, TX_FALSE) == TX_RESULT_OK;
    success &= InitializeGlobalInteractorSnapshot(hContext);
    success &= txRegisterConnectionStateChangedHandler(hContext, &hConnectionStateChangedTicket, &OnEngineConnectionStateChanged, nullptr) == TX_RESULT_OK;
    success &= txRegisterEventHandler(hContext, &hEventHandlerTicket, HandleEvent, nullptr) == TX_RESULT_OK;
    success &= txEnableConnection(hContext) == TX_RESULT_OK;

    // let the events flow until a key is pressed.
    if (success) {
        qDebug() << "(EyeX) Initialization was successful.";
    } else {
        qDebug() << "(EyeX) Initialization failed.";
    }
}

void release()
{
    // disable and delete the context.
    bool success;
    txDisableConnection(hContext);
    txReleaseObject(&g_hGlobalInteractorSnapshot);
    success = txShutdownContext(hContext, TX_CLEANUPTIMEOUT_DEFAULT, TX_FALSE) == TX_RESULT_OK;
    success &= txReleaseContext(&hContext) == TX_RESULT_OK;
    success &= txUninitializeEyeX() == TX_RESULT_OK;
    if (!success) {
        qDebug() << "EyeX could not be shut down cleanly. Did you remember to release all handles?";
    }
}

/*
 * Initializes g_hGlobalInteractorSnapshot with an interactor that has the Gaze Point behavior.
 */
bool InitializeGlobalInteractorSnapshot(TX_CONTEXTHANDLE hContext)
{
    TX_HANDLE hInteractor = TX_EMPTY_HANDLE;

    TX_GAZEPOINTDATAPARAMS paramsGaze = { TX_GAZEPOINTDATAMODE_LIGHTLYFILTERED };
    TX_FIXATIONDATAPARAMS paramsFix = { TX_FIXATIONDATAMODE_SLOW };

    bool success;

    success = txCreateGlobalInteractorSnapshot(
        hContext,
        InteractorId,
        &g_hGlobalInteractorSnapshot,
        &hInteractor) == TX_RESULT_OK;
    if (USE_FIXATIONS) success &= txCreateFixationDataBehavior(hInteractor, &paramsFix) == TX_RESULT_OK;
    else success &= txCreateGazePointDataBehavior(hInteractor, &paramsGaze) == TX_RESULT_OK;

    txReleaseObject(&hInteractor);

    return success;
}

/*
 * Callback function invoked when a snapshot has been committed.
 */
void TX_CALLCONVENTION OnSnapshotCommitted(TX_CONSTHANDLE hAsyncData, TX_USERPARAM param)
{
    Q_UNUSED(param)
    // check the result code using an assertion.
    // this will catch validation errors and runtime errors in debug builds. in release builds it won't do anything.

    TX_RESULT result = TX_RESULT_UNKNOWN;
    txGetAsyncDataResultCode(hAsyncData, &result);
    assert(result == TX_RESULT_OK || result == TX_RESULT_CANCELLED);
}

/*
 * Callback function invoked when the status of the connection to the EyeX Engine has changed.
 */
void TX_CALLCONVENTION OnEngineConnectionStateChanged(TX_CONNECTIONSTATE connectionState,
                                                                     TX_USERPARAM userParam)
{
    Q_UNUSED(userParam)
    switch (connectionState) {
    case TX_CONNECTIONSTATE_CONNECTED: {
            bool success;
            qDebug() << "(EyeX) The connection state is now CONNECTED (We are connected to the EyeX Engine)";
            // commit the snapshot with the global interactor as soon as the connection to the engine is established.
            // (it cannot be done earlier because committing means "send to the engine".)
            success = txCommitSnapshotAsync(g_hGlobalInteractorSnapshot, OnSnapshotCommitted, nullptr) == TX_RESULT_OK;
            if (!success) {
                qDebug() << "(EyeX) Failed to initialize the data stream.";
            }
            else {
                qDebug() << "(EyeX) Waiting for gaze data to start streaming...";
            }
        }
        break;

    case TX_CONNECTIONSTATE_DISCONNECTED:
        qDebug() << "(EyeX) The connection state is now DISCONNECTED (We are disconnected from the EyeX Engine)";
        break;

    case TX_CONNECTIONSTATE_TRYINGTOCONNECT:
        qDebug() << "(EyeX) The connection state is now TRYINGTOCONNECT (We are trying to connect to the EyeX Engine)";
        break;

    case TX_CONNECTIONSTATE_SERVERVERSIONTOOLOW:
        qDebug() << "(EyeX) The connection state is now SERVER_VERSION_TOO_LOW: this application requires a more recent version of the EyeX Engine to run.";
        break;

    case TX_CONNECTIONSTATE_SERVERVERSIONTOOHIGH:
        qDebug() << "(EyeX) The connection state is now SERVER_VERSION_TOO_HIGH: this application requires an older version of the EyeX Engine to run.";
        break;
    }
}

void OnGazeDataEvent(TX_HANDLE hGazeDataBehavior)
{
    TX_GAZEPOINTDATAEVENTPARAMS eventParams;
    if (txGetGazePointDataEventParams(hGazeDataBehavior, &eventParams) == TX_RESULT_OK) {
        // We will use the current timestamp instead of eventParams.Timestamp
        // With a single reference for all the timestamps it is easier to work with the events
        emit emitter->newGaze(SamplePoint(Timer::timestamp(), QPointF(eventParams.X, eventParams.Y)));
    } else {
        qDebug() << "(EyeX) Failed to interpret gaze data event packet.";
    }
}


/*
 * Handles an event from the Gaze Point data stream.
 */
void OnFixationDataEvent(TX_HANDLE hFixationDataBehavior)
{
    TX_FIXATIONDATAEVENTPARAMS eventParams;
    TX_FIXATIONDATAEVENTTYPE eventType;

    if (txGetFixationDataEventParams(hFixationDataBehavior, &eventParams) == TX_RESULT_OK) {
        // We will use the current timestamp instead of eventParams.Timestamp
        // With a single reference for all the timestamps it is easier to work with the events
        eventType = eventParams.EventType;

        if (eventParams.X == eventParams.X && eventParams.Y == eventParams.Y) // is not NAN
        {
            emit emitter->newGaze(SamplePoint(Timer::timestamp(), QPointF(eventParams.X, eventParams.Y)));
        }
    } else {
        qDebug() << "(EyeX) Failed to interpret gaze data event packet.";
    }
}

/*
 * Callback function invoked when an event has been received from the EyeX Engine.
 */
void TX_CALLCONVENTION HandleEvent(TX_CONSTHANDLE hAsyncData, TX_USERPARAM userParam)
{
    Q_UNUSED(userParam)
    TX_HANDLE hEvent = TX_EMPTY_HANDLE;
    TX_HANDLE hBehavior = TX_EMPTY_HANDLE;

    txGetAsyncDataContent(hAsyncData, &hEvent);

    // NOTE. Uncomment the following line of code to view the event object. The same function can be used with any interaction object.
    //OutputDebugStringA(txDebugObject(hEvent));

    if (!USE_FIXATIONS && txGetEventBehavior(hEvent, &hBehavior, TX_BEHAVIORTYPE_GAZEPOINTDATA) == TX_RESULT_OK)
    {
        OnGazeDataEvent(hBehavior);
        txReleaseObject(&hBehavior);
    }

    if (USE_FIXATIONS && txGetEventBehavior(hEvent, &hBehavior, TX_BEHAVIORTYPE_FIXATIONDATA) == TX_RESULT_OK)
    {
        OnFixationDataEvent(hBehavior);
        txReleaseObject(&hBehavior);
    }

    // NOTE since this is a very simple application with a single interactor and a single data stream,
    // our event handling code can be very simple too. A more complex application would typically have to
    // check for multiple behaviors and route events based on interactor IDs.

    txReleaseObject(&hEvent);
}
#else

TobiiListener::TobiiListener(QObject *root, bool controlling) :
    QObject(root), controlling(controlling)
{
}

TobiiListener::~TobiiListener()
{
}

void TobiiListener::setControlling(bool controlling)
{
    this->controlling = controlling;
}

void TobiiListener::controlToggled(bool notControlling)
{
    controlling = !notControlling;
}

void TobiiListener::onGaze(SamplePoint gaze)
{
    if (controlling)
    {
        emit newGaze(gaze);
    }
}

#endif
