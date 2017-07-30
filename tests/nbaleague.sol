pragma solidity ^0.4.10;

contract NBALeague {
    
    mapping (uint => Each) allCompetitions;

    
    struct Each {
        Tournament tournament;
        uint num;
    }
    uint numTournaments = 0;
    
    function createTournament
    (string name, uint fee) returns (string){
        Each e = allCompetitions[numTournaments];
        e.tournament = new Tournament(name);
        e.num = numTournaments;
        e.tournament.setAll(fee);
        numTournaments++;
    }
    
    function createCategories
    (uint numTournament, 
    string cat1, string cat2, string cat3, string cat4, string cat5) {
        allCompetitions[numTournament].tournament.setCategories(cat1, cat2, cat3, cat4, cat5);
    }
    
    function setMultipliers(uint numTournament,
    uint mult1, uint mult2, uint mult3, uint mult4, uint mult5) {
        allCompetitions[numTournament].tournament.setMultipliers(mult1, mult2, mult3,
        mult4, mult5);
    }
    
    function addPlayer
    (uint numTournament, address user, string playerName, string playerPos) {
        allCompetitions[numTournament].tournament.addPlayerToRoster(user, playerName, playerPos);
    }
    
    function deletePlayer
    (uint numTournament, address user, string playerName, string playerPos) {
        allCompetitions[numTournament].tournament.addPlayerToRoster(user, playerName, playerPos);
    }
    
    function rosterPoints
    (uint numTournament, string playerName, 
    uint stat1, uint stat2, uint stat3, uint stat4, uint stat5) {
        allCompetitions[numTournament].tournament.rosterPoints(playerName, stat1, 
        stat2, stat3, stat4, stat5);
    }
    
    function computeUsersScores(uint numTournament) {
        allCompetitions[numTournament].tournament.computeUsersScores();
    }
    
    function initializeUser(uint numTournament, string userName, address addr) {
        allCompetitions[numTournament].tournament.initializeUser(userName, addr);
    }

    
}
contract Tournament{

    //Global variables. Some constant for every tournament. Others depend on the contract.
    address owner = 0x2B1e5AFAF117788DFe82C92f4ee82ad427721174;
    uint pot = 0;
    string tournamentName;
    uint entryFee;
    bool isLocked = false;
    
    
    //find the winning categories and their respective multipliers;
    mapping(string => uint) winningCategories;
    mapping(uint => string) findCategories;
    uint numCategories;
    
    //mappings to find users by index and then subsequently store addresses as well.
    mapping (address => User) listUsers;
    mapping (uint => address) listUsersByIndex;
    uint numUsers = 0;
    
    //stores the points with our mulitplier applied to it, for easy access.
    mapping(string => uint) playerPoints;
    
    struct User {
        /*
        Struct stores each users address and a mapping of their selected rosters. It also stores their end-of-tournament  score.
        */
        string userName;
        uint score;
        mapping(uint => Player) roster;
        uint numPlayers;
        bool rosterFull;
    }
    
    struct Player {
        string name;
        string position;
        bool initialized;
    }
    //     modifier startTime() {
    //     if (now - (GAME_ STARTS - 300) > 0) {
    //         throw;
    //     }
    //     _;
    // }
    
    // modifier tourneyExists(string T) {
    //     tourney memory currT = NBA;
    //     if (currT.entryFee == 0) {
    //         throw;
    //     }
    //     _;
    // }
    
    // modifier entryFee(tourney t) {
    //     if (msg.value != t.entryFee) {
    //         throw;
    //     }
    //     _;
    // }

    // modifier isPlayerAvailable(uint playerID) {
    //     bool exists = false;
    //     for (uint i = 0; i < 30; i++) {
    //         if (NBA.playerList[i].playerID == playerID) {
    //             Player storage p = NBA.playerList[i];
    //         }
    //     }
    //     if (exists) {
    //         _;
    //     }
    // }
    //Various Helper Functions
    
    //Function to compare if two strings are equal or not.
    function stringsEqual(string _a, string _b) internal returns (bool) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        if (a.length != b.length)
            return false;
        // @todo unroll this loop
        for (uint i = 0; i < a.length; i ++)
            if (a[i] != b[i])
                return false;
        return true;
    }
    
    //modifiers
    modifier locked() {
        if (isLocked) throw;
        _;
    }
    
    //Tournament constructor. To be called by League contract.
    function Tournament(string name) {
        tournamentName = name;
    }
    function lockTournament() {
        isLocked = true;
    }
    
    function setAll
    (uint fee) 
    {
        entryFee = fee;
        numCategories = 5;
    }
    
    function setCategories
    (string cat1, string cat2, string cat3, string cat4, string cat5) {
        findCategories[1] = cat1;
        findCategories[2] = cat2;
        findCategories[3] = cat3;
        findCategories[4] = cat4;
        findCategories[5] = cat5;
    }
    
    function setMultipliers
    (uint mult1, uint mult2, uint mult3, uint mult4, uint mult5) {
        winningCategories[findCategories[1]] = mult1;
        winningCategories[findCategories[2]] = mult2;
        winningCategories[findCategories[3]] = mult3;
        winningCategories[findCategories[4]] = mult4;
        winningCategories[findCategories[5]] = mult5;
        
    }
    
    
    //Initializes user object in mapping with correct values.
    function initializeUser(string name, address addr) locked returns (string) {
        listUsers[addr].userName = name;
        listUsers[addr].score = 0;
        listUsers[addr].numPlayers = 0;
        listUsers[addr].rosterFull = false;
        listUsersByIndex[numUsers] = addr;
        numUsers++;
        pot += entryFee;
        if (numUsers == 100) lockTournament();
    }
    
    //Adds player to last available index of a users roster.
    function addPlayerToRoster(address addr, string playerName, string playerPos) locked returns (string) {
       User u = listUsers[addr];
       if (stringsEqual(playerPos, "PG")) {
           if (!u.roster[0].initialized) {
               u.roster[0].name = playerName;
               u.roster[0].position = playerPos;
               u.roster[0].initialized = true;
           }
           else if (!u.roster[1].initialized) {
               u.roster[1].name = playerName;
               u.roster[1].position = playerPos;
               u.roster[1].initialized = true;
           }
           else {
               throw;
           }
       } 
       if (stringsEqual(playerPos, "SG")) {
           if (!u.roster[2].initialized) {
               u.roster[2].name = playerName;
               u.roster[2].position = playerPos;
               u.roster[2].initialized = true;
           }
           else if (!u.roster[3].initialized) {
               u.roster[3].name = playerName;
               u.roster[3].position = playerPos;
               u.roster[3].initialized = true;
           }
           else {
               throw;
           }
       } 
       if (stringsEqual(playerPos, "C")) {
           if (!u.roster[4].initialized) {
               u.roster[4].name = playerName;
               u.roster[4].position = playerPos;
               u.roster[4].initialized = true;
           }
           else if (!u.roster[5].initialized) {
               u.roster[5].name = playerName;
               u.roster[5].position = playerPos;
               u.roster[5].initialized = true;
           }
           else {
               throw;
           }
       } 
       if (stringsEqual(playerPos, "SF")) {
           if (!u.roster[6].initialized) {
               u.roster[6].name = playerName;
               u.roster[6].position = playerPos;
               u.roster[6].initialized = true;
           }
           else if (!u.roster[7].initialized) {
               u.roster[7].name = playerName;
               u.roster[7].position = playerPos;
               u.roster[7].initialized = true;
           }
           else {
               throw;
           }
       } 
       if (stringsEqual(playerPos, "PF")) {
           if (!u.roster[8].initialized) {
               u.roster[8].name = playerName;
               u.roster[8].position = playerPos;
               u.roster[8].initialized = true;
           }
           else if (!u.roster[9].initialized) {
               u.roster[9].name = playerName;
               u.roster[9].position = playerPos;
               u.roster[9].initialized = true;
           }
           else {
               throw;
           }
       } 
       return playerName;
    }
    
    //Deletes player from index in mapping.
    function deletePlayer(address addr, string playerName, string playerPos) locked {
        User u = listUsers[addr];
        if (stringsEqual(playerPos, "PG")) {
           if (stringsEqual(u.roster[0].name, playerName)) {
               u.roster[0].initialized = false;
           }
           else if (stringsEqual(u.roster[1].name, playerName)) {
               u.roster[1].initialized = false;
           }
           else {
               throw;
           }
       } 
      if (stringsEqual(playerPos, "SG")) {
           if (stringsEqual(u.roster[2].name, playerName)) {
               u.roster[2].initialized = false;
           }
           else if (stringsEqual(u.roster[3].name, playerName)) {
               u.roster[3].initialized = false;
           }
           else {
               throw;
           }
       } 
       if (stringsEqual(playerPos, "C")) {
           if (stringsEqual(u.roster[4].name, playerName)) {
               u.roster[4].initialized = false;
           }
           else if (stringsEqual(u.roster[5].name, playerName)) {
               u.roster[5].initialized = false;
           }
           else {
               throw;
           }
       } 
       if (stringsEqual(playerPos, "SF")) {
           if (stringsEqual(u.roster[6].name, playerName)) {
               u.roster[6].initialized = false;
           }
           else if (stringsEqual(u.roster[7].name, playerName)) {
               u.roster[7].initialized = false;
           }
           else {
               throw;
           }
       } 
       if (stringsEqual(playerPos, "PF")) {
           if (stringsEqual(u.roster[8].name, playerName)) {
               u.roster[8].initialized = false;
           }
           else if (stringsEqual(u.roster[9].name, playerName)) {
               u.roster[9].initialized = false;
           }
           else {
               throw;
           }
       }
        
    }
    
    //Computes each NBA players points scored after each game.
    function rosterPoints(string playerName, uint stat1, uint stat2, uint stat3, uint stat4, uint stat5) returns (uint) {
        playerPoints[playerName] = stat1 * winningCategories[findCategories[0]] + 
        stat2 * winningCategories[findCategories[1]] + 
        stat3 * winningCategories[findCategories[2]] + 
        stat4 * winningCategories[findCategories[3]] + 
        stat5 * winningCategories[findCategories[4]];
    }
    
    //Computes each users roster score after the games have ended
    function computeUsersScores() {
        for (uint i = 0; i < numUsers; i++) {
            User toCompute = listUsers[listUsersByIndex[i]];
            for (uint j = 0; j < toCompute.numPlayers; j++) {
                toCompute.score += playerPoints[toCompute.roster[j].name];
            }
        }
        
        findWinners();
    }
    
    //Finds the top 3 positions for the tournament.
    function findWinners() internal  {
            
        uint first = 0;
        uint second = 0;
        uint third = 0;
        uint temp = 0;
        
        address firstPlace;
        address secondPlace;
        address thirdPlace;
        address tempAddr;
        
        for (uint i = 0; i < numUsers; i++){
            temp = listUsers[listUsersByIndex[i]].score;
            tempAddr = listUsersByIndex[i];
            if (temp >= first){
                //Change points of winners
                third = second;
                second = first;
                first = temp;
                
                //Change addresses of winners
                thirdPlace = secondPlace;
                secondPlace = firstPlace;
                firstPlace = tempAddr;
            } else if (temp >= second){
                third = second;
                second = temp;
                
                thirdPlace = secondPlace;
                secondPlace = tempAddr;
                
            } else if (temp >= third){
                third = temp;
                
                thirdPlace = tempAddr;
            }
        }
        
        dispensePoints(firstPlace, 1);
        dispensePoints(secondPlace, 2);
        dispensePoints(thirdPlace, 3);
        selfdestruct(owner);            
    }
    
    function dispensePoints(address addr, uint position) internal {
        uint factor = 1;
        if (position == 1) {
            factor = 2;
        } else if (position == 2) {
            factor = 4;
        } else {
            factor = 8;
        }
        if (!addr.send(pot / factor)) {
            throw;
        }
    }
    
    function printRoster(address addr) returns (string) {
        User u = listUsers[addr];
        string memory begin = "Roster: ";
        for (uint i = 0; i < 10; i++) {
            begin = strConcat(begin, u.roster[i].name);
        }
        return begin;
        
    }
    
    //strConcat functions
    function strConcat(string _a, string _b, string _c, string _d, string _e) internal returns (string){
    bytes memory _ba = bytes(_a);
    bytes memory _bb = bytes(_b);
    bytes memory _bc = bytes(_c);
    bytes memory _bd = bytes(_d);
    bytes memory _be = bytes(_e);
    string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
    bytes memory babcde = bytes(abcde);
    uint k = 0;
    for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
    for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
    for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
    for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
    for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
    return string(babcde);
}

function strConcat(string _a, string _b, string _c, string _d) internal returns (string) {
    return strConcat(_a, _b, _c, _d, "");
}

function strConcat(string _a, string _b, string _c) internal returns (string) {
    return strConcat(_a, _b, _c, "", "");
}

function strConcat(string _a, string _b) internal returns (string) {
    return strConcat(_a, _b, "", "", "");
}
}