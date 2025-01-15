class Proto extends AIController {
    AirController = null;

    function Start();

    constructor(){
        require("Air.nut");
        //require("Tram.nut");
        this.AirController = Air();
        //this.TramController = Tram();
	}
};

function Proto::Start()
{
    Sleep(1)
    if (!AICompany.SetName("ProtoCorp")) {
        local i = 2;
        while (!AICompany.SetName("ProtoCorp #" + i)){
            i++;
        }
    }

    local ticker = 0;

    while (true) {
        local cash = AICompany.GetBankBalance(AICompany.COMPANY_SELF);

        if(ticker % 1000 == 0){
            AirController.turn(cash);
            //TramController.Turn(cash/2);
        }
        Sleep(500);
    }
}