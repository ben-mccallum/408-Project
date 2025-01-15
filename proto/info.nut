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
        return 3;
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
}

RegisterAI(Proto());