// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./EternalContract.sol";

interface IEternalContract{
    function registerPlayer(address _player) external;
    function setEnum1(bytes32 key, bytes32 value) external;
    function setEnum2(bytes32 key, uint value) external;
    function _chosenSign(address player, bytes32 _chosenSign ) external;
    function chosenHand(address player, uint _playerHands) external;
    function matchReward(address player1, address player2 ) external;
     function updateBalance(address _player, uint _amount) external;

    function getPlayerStatus(address _player)external view returns(bool);
    function getEnum1(bytes32 key) external view returns(bytes32);
    function getEnum2(bytes32 key) external view returns(uint);
    function _getChoosenSign(address player) external view returns(bytes32);
    function getChosenHand(address player) external view returns(bytes32);
    function getPlayerInformation(address _player) external view returns(EternalContract.Player memory);
    function getBalance(address _player) external view returns (uint);
    }

contract LogicContract{
    IEternalContract private eternalContract;
    address public owner;
    address payable public contractAddr;
    //mapping(address => eternalContract.Player) addPlayer;
    // address [] playerAddress;
    address[] private waitingPlayers;
    mapping(address=>bool) public isPlaying;
    //bytes32 public eternalContract._getChoosenSign;
    uint public count;

    receive() external payable { }
    constructor(address _eternalContractAddress){
        owner = msg.sender;
        eternalContract =IEternalContract(_eternalContractAddress);
        contractAddr = payable(address(this));
    }

    modifier onlyExistedPlayer() {
        require(eternalContract.getPlayerStatus(msg.sender) == true, "Only owner can call this function.");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    function _registerPlayer(address _playerAddress) external{
        require(eternalContract.getPlayerStatus(_playerAddress) != true, "The player is already registered.");
        eternalContract.registerPlayer(_playerAddress);
     }

     function deposit()external payable returns(bool){
        require( msg.value>= 0, "Invalid Value");
        return contractAddr.send(msg.value);
    }

    function depositFromPlayer()external payable{
        require( msg.value>= 0, "Invalid Value");
        contractAddr.transfer(msg.value);
        uint amount = msg.value;
        eternalContract.updateBalance(msg.sender, amount);
    }

    function withdrawalPlayers(uint _amount)external payable{
        require(_amount <= eternalContract.getBalance(msg.sender), "Insufficient funds.");
        payable(msg.sender).transfer(_amount);
        eternalContract.updateBalance(msg.sender, eternalContract.getBalance(msg.sender) - _amount);
     }

    function transfer(uint amount, address payable _to)external onlyOwner payable returns(bool){
        require(address(this).balance >= amount, "Insufficient Funds");
        return _to.send(amount);
    }

    function commit(bytes32 hands) external onlyExistedPlayer{
        require(isPlaying[msg.sender] != true, "You have already committed.");
        eternalContract._chosenSign(msg.sender, hands);
        isPlaying[msg.sender] = true;
    }

    function reveal(string memory hands, string memory salt) external onlyExistedPlayer{
        bytes32 actualAnswer =keccak256(abi.encodePacked(hands, salt));
        bytes32 hashedAnswer = eternalContract._getChoosenSign(msg.sender);
        
        if(hashedAnswer == actualAnswer) getHands(keccak256(abi.encodePacked(hands)));
        else revert(string(abi.encodePacked("sorry ", "you failed")));
    }

    function getHands(bytes32 hands) private {
        if(hands == keccak256("rock")){
           eternalContract.chosenHand(msg.sender, 0);
        }else if(hands == keccak256("paper")) {
            eternalContract.chosenHand(msg.sender, 1);
        }else if(hands == keccak256("scissor")) {
            eternalContract.chosenHand(msg.sender, 2);
        }else {
            revert("Invalid hands");
        }
     }

    // Function to add a player to the matchmaking pool
    function joinMatchmaking() external onlyExistedPlayer{
        require(msg.sender != address(0), "Invalid address");

        // Check if the player is already in the waiting list
        for (uint i = 0; i < waitingPlayers.length; i++) {
            if (waitingPlayers[i] == msg.sender) {
                revert("Player already in matchmaking");
            }
        }

        waitingPlayers.push(msg.sender);

        // If we have at least two players, make a match
        if (waitingPlayers.length > 1) {
            makeMatch();
        }
    }

    // Internal function to make a match
    function makeMatch() public onlyExistedPlayer {
        require(waitingPlayers.length >= 2, "Not enough players");

        // Use block.prevrandao for randomness (only available from Ethereum merge)
        uint randomIndex = uint(keccak256(abi.encodePacked(block.prevrandao, block.timestamp, waitingPlayers.length))) % waitingPlayers.length;

        address playerA = waitingPlayers[randomIndex];
        // Remove playerA from the array
        waitingPlayers[randomIndex] = waitingPlayers[waitingPlayers.length - 1];
        waitingPlayers.pop();

        // Select playerB (now the array length has changed)
        randomIndex = uint(keccak256(abi.encodePacked(block.prevrandao, block.timestamp, waitingPlayers.length))) % waitingPlayers.length;
        address playerB = waitingPlayers[randomIndex];
        //Remove playerB from the array
        waitingPlayers[randomIndex] = waitingPlayers[waitingPlayers.length - 1];
        waitingPlayers.pop();
        winningCondition(playerA, playerB);
        isPlaying[playerA] = false;
        isPlaying[playerB] = false;
       
        }

    function _getChoosenSign(address _player) external view returns(bytes32){
        return eternalContract.getChosenHand(_player);
    }

    function winningCondition(address _playerA, address _playerB) private {
        if(eternalContract.getChosenHand(_playerA) == keccak256("rock") && eternalContract.getChosenHand(_playerB) == keccak256("scissor") || 
        eternalContract.getChosenHand(_playerA) == keccak256("scissor") && eternalContract.getChosenHand(_playerB) == keccak256("paper")||
        eternalContract.getChosenHand(_playerA) == keccak256("paper") && eternalContract.getChosenHand(_playerB) == keccak256("rock")) {
            eternalContract.matchReward(_playerA, _playerB);
        }else if(eternalContract.getChosenHand(_playerB) == keccak256("rock") && eternalContract.getChosenHand(_playerA) == keccak256("scissor") || 
        eternalContract.getChosenHand(_playerB) == keccak256("scissor") && eternalContract.getChosenHand(_playerA) == keccak256("paper")||
        eternalContract.getChosenHand(_playerB) == keccak256("paper") && eternalContract.getChosenHand(_playerA) == keccak256("rock")){
            eternalContract.matchReward(_playerB, _playerA);
        }else{
            revert("Invalid hands");
        }}
    // Function to get the number of players waiting for a match
    function getWaitingPlayersCount() external view returns (uint) {
        return waitingPlayers.length;
    }
}