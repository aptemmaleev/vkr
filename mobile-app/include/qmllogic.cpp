#include "incldue/qmllogic.h"

QmlLogic::QmlLogic(QObject *parent)
    : QObject{parent}
{


}

User QmlLogic::getCurrentUser() const
{
    return currentUser;
}
