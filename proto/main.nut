class Proto extends AIController
{
    function Start();
}

function Proto::Start()
{
    if (!AICompany.SetName("ProtoCorp")) {
        local i = 2;
        while (!AICompant.SetName("ProtoCorp #" + i)){
            i++;
        }
    }


    while (true) {
        while (AIEventController.IsEventWaiting()) {
            local e = AIEventController.GetNextEvent();
            switch (e.GetEventType()) {
                case AIEvent.ET_VEHICLE_CRASHED:
                    local ec = AIEventVehicleCrashed.Convert(e);
                    local v = ec.GetVehicleID();
                    AILog.Info("We have a crashed vehicle (" + v + ")");
                    /* Do something about it */
                    break;
            }
        }
    }
}