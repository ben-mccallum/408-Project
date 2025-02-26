Class Chopper extends AIController{
    function Start();
    constructor(){
        station_age_list = AIList();
        switch(GetSetting("attitude")){
            case 4:
                this.delay_build_airport_route = 10;
                break;
            case 3:
                this.delay_build_airport_route = 500;
                break;
            case 2:
                this.delay_build_airport_route = 1000;
                break;
            case 1:
                this.delay_build_airport_route = 2000;
                break;
            case 0:
                this.delay_build_airport_route = 4000;
                break;
        }

        this.STATIONS_PER_INDUSTRY = GetSetting("stations_per_industry");
        this.min_station_dis = GetSetting("min_station_dis");
        this.max_station_dis = GetSetting("max_station_dis");
        if(this.max_station_dis < this.min_station_dis + 25){
            this.max_station_dis = this.min_station_dis + 25;
        }

        this.min_industry_dis = GetSetting()
    }
}