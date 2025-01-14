class Proto extends AIInfo{
    function GetAuthor() {
        return "Ben";
    }
    function GetName(){
        return "Proto";
    }
    function GetDescription(){
        return "Prototype AI for testing purposes.";
    }
    function GetVersion(){
        return 1;
    }
    function GetDate(){
        return "2024-12-06";
    }
    function CreateInstance(){
        return "Proto";
    }
    function GetShortName(){
        return "PROT";
    }
    function GetAPIVersion(){
        return "12";
    }
}

RegisterAI(Proto());