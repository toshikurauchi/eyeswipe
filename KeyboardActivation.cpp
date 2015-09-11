#include <QPointF>
#include <QDebug>

#include "KeyboardActivation.h"
#include "Timer.h"

// IKeyboardActivation

IKeyboardActivation::IKeyboardActivation(QObject *parent) : QObject(parent)
{}

// DwellKeyboardActivation

DwellKeyboardActivation::DwellKeyboardActivation(QObject *root, KeyboardLayout &layout) :
    IKeyboardActivation(root), layout(layout), currentButton(NULL)
{
}

void DwellKeyboardActivation::updateKeyboard(SamplePoint pointer)
{
    KeyboardButton button = layout.buttonAt(pointer.value);
    double extraTime = clicks ? 1000 : 0;
    if (!currentButton.valid || button.value != currentButton.value)
    {
        dwellReference = pointer;
        clicks = 0;
        currentButton.mouseOut();
        currentButton = button;
    }
    if (pointer.tstamp - dwellReference.tstamp > DWELL_TIME + extraTime)
    {
        dwellReference = pointer;
        if (button.clicked())
        {
            clicks++;
            emit toggleGesture(button, Timer::timestamp());
        }
    }
    else if (pointer.tstamp - dwellReference.tstamp > SELECTION_TIME + extraTime)
    {
        button.selected();
    }
}

// PEyeKeyboardActivation

PEyeKeyboardActivation::PEyeKeyboardActivation(QObject *root, KeyboardLayout &layout) :
    IKeyboardActivation(root), layout(layout), currentButton(NULL)
{
}

void PEyeKeyboardActivation::updateKeyboard(SamplePoint pointer)
{
    KeyboardButton button = layout.buttonAt(pointer.value);
    if (menu.isActive())
    {
        Button *prevButton = menu.getLastFocusedButton();
        menu.setFocus(pointer.value);
        Button *focusedButton = menu.getFocusedButton();
        if (focusedButton == NULL)
        {
            if (!menu.hasFocus()) menu.hide();
        }
        else if (focusedButton != prevButton)
        {
            focusedButton->selected();
            if (focusedButton->button == currentButton.button)
            {
                dwellReference = pointer; // Reset dwell time
                if (prevButton->button == layout.getPEyeGesture())
                {
                    menu.hide();
                    menu.toggleGesture();
                    emit toggleGesture(currentButton, enterTimestamp);
                }
                else if (prevButton->button == layout.getPEyeKeystroke())
                {
                    menu.hide();
                    emit keystroke(currentButton);
                }
                else if (prevButton->button == layout.getPEyeCancel())
                {
                    menu.hide();
                    menu.toggleGesture();
                    emit cancelGesture();
                }
            }
        }
    }
    else if (!currentButton.valid || button.value != currentButton.value)
    {
        dwellReference = pointer;
        currentButton.mouseOut();
        currentButton = button;
    }
    else if (pointer.tstamp - dwellReference.tstamp > SELECTION_TIME)
    {
        button.selected();
        menu = layout.menuFor(button);
        menu.show();
        menu.setFocus(pointer.value);
        enterTimestamp = Timer::timestamp();
    }
}
