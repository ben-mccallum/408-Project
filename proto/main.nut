class Proto extends AIController {
    AirController = null;
    SeaController = null;
    ratio = 50;

    function Start();

    constructor(){
        require("Air.nut");
        require("Sea.nut");
        this.AirController = Air();
        this.SeaController = Sea();
	}
}

function Proto::Eval(type){
    local vehs = AIVehicleList_DefaultGroup(type);
    local profit = 0;
    for (local ve = vehs.Begin(); vehs.HasNext(); ve = vehs.Next()){
        local temp = 0;
        temp += ve.GetProfitThisYear;
        temp += ve.GetProfitLastYear;
        temp = temp / ve.GetAge;
        profit += temp;
    }
}

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
            AirController.turn(cash/ratio);
            SeaController.turn(cash/(100-ratio));
            local airProfit = Eval(AIVehicle.VT_AIR);
            local seaProfit = Eval(AIVehicle.VT_WATER);
            if (airProfit > seaProfit){
                ratio -= 5;
            }else{
                ratio += 5;
            }
        }
        Sleep(500);
    }
}